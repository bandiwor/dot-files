#!/usr/bin/env bash
# Дисплеи (Mod+I): яркость ноутбука (brightnessctl) и внешнего монитора (ddcutil), питание экранов.
# Меню открывается мгновенно: DDC/CI медленный (0.5–2 с), поэтому яркость HDMI берётся из кэша,
# а актуальное значение подтягивается фоном для следующего открытия.
# Выбор по индексу (fuzzel --index).

UI_TITLE=DISPLAY UI_TAG=display-hub
. "$(dirname "$(readlink -f "$0")")/lib/common.sh"

CACHE="${XDG_RUNTIME_DIR:-/tmp}/niri-ddc-brightness"

laptop_get() { brightnessctl -m 2>/dev/null | head -n 1 | cut -d, -f4 | tr -d '%'; }

ext_read() { ddcutil getvcp 10 --brief 2>/dev/null | awk '{print $4}'; }

ext_refresh_bg() {
    ( v=$(ext_read); [ -n "$v" ] && echo "$v" >"$CACHE" ) >/dev/null 2>&1 &
}

# Выбор уровня: пресеты + шаги. $1 — заголовок, $2 — текущее значение
pick_level() {
    local -a items=("+10" "-10" 100 90 80 70 60 50 40 30 20 10 5)
    local idx
    idx=$(printf '%s%%\n' "${items[@]}" | fz --index --lines 12 --width 24 --prompt "$1 ($2%) -> ") || return 1
    [ -z "$idx" ] && return 1
    printf '%s' "${items[idx]}"
}

set_laptop() {
    local cur new
    cur=$(laptop_get); cur=${cur:-0}
    new=$(pick_level "Ноутбук" "$cur") || return 1
    case "$new" in
        +*|-*) new=$(clamp $(( cur + new )) 1 100) ;;
    esac
    brightnessctl set "${new}%" >/dev/null 2>&1 || { notify_err "Не удалось изменить яркость ноутбука"; return 1; }
    notify "Яркость ноутбука: $(laptop_get)%"
}

set_ext() {
    local cur new
    cur=$(cat "$CACHE" 2>/dev/null); cur=${cur:-50}
    new=$(pick_level "HDMI" "$cur") || return 1
    case "$new" in
        +*|-*)
            # относительный шаг считаем от свежего значения
            local fresh; fresh=$(ext_read); cur=${fresh:-$cur}
            new=$(clamp $(( cur + new )) 0 100)
            ;;
    esac
    notify "HDMI: установка яркости ${new}%..."
    if ddcutil setvcp 10 "$new" --noverify >/dev/null 2>&1; then
        echo "$new" >"$CACHE"
        notify "Яркость HDMI: ${new}%"
    else
        notify_err "DDC/CI недоступен (монитор не отвечает)"
        return 1
    fi
}

while true; do
    ext_refresh_bg

    menu_reset

    if LAP=$(laptop_get) && [ -n "$LAP" ]; then
        add "$(bar "$LAP")  $(printf '%3d' "$LAP")%  Ноутбук" laptop
    fi
    EXT=$(cat "$CACHE" 2>/dev/null)
    if [ -n "$EXT" ]; then
        add "$(bar "$EXT")  $(printf '%3d' "$EXT")%  HDMI" ext
    else
        add "░░░░░░░░░░    —   HDMI" ext
    fi
    add "────────────────────────────────────────" none
    add "⏻ HDMI: Standby (выключить питание)" ext_off
    add "⏻ HDMI: Включить питание" ext_on
    add "⏻ Все экраны: выключить (DPMS)" dpms

    IDX=$(show_menu "DISPLAY -> " 50) || exit 0
    [ -z "$IDX" ] && exit 0

    case "${KIND[IDX]}" in
        laptop) set_laptop ;;   # после изменения возвращаемся в меню, Esc — выход
        ext)    set_ext ;;
        ext_off)
            # VCP D6 0x04: DPM Standby
            if ddcutil setvcp D6 4 --noverify >/dev/null 2>&1; then notify "HDMI монитор переведён в Standby"
            else notify_err "DDC/CI недоступен"; fi
            exit 0
            ;;
        ext_on)
            # VCP D6 0x01: DPM Normal On
            if ddcutil setvcp D6 1 --noverify >/dev/null 2>&1; then notify "HDMI монитор включён"
            else notify_err "DDC/CI недоступен"; fi
            exit 0
            ;;
        dpms)
            niri msg action power-off-monitors
            exit 0
            ;;
    esac
done
