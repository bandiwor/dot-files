#!/usr/bin/env bash
# Питание (Mod+P): батарея, профиль (power-profiles-daemon), Turbo Boost, лимит заряда.
# Профили — через powerprofilesctl: без root и без конфликта с демоном
# (раньше скрипт писал EPP в /sys напрямую и воевал с power-profiles-daemon).
# Запись в /sys (boost, лимит заряда) идёт с повышением прав и явной ошибкой, а не молча.
# Выбор по индексу (fuzzel --index). После действия возвращаемся в меню, Esc — выход.

UI_TITLE=POWER UI_TAG=power-hub
. "$(dirname "$(readlink -f "$0")")/lib/common.sh"

BAT=$(find /sys/class/power_supply -maxdepth 1 -name 'BAT*' 2>/dev/null | head -n 1)
BOOST=/sys/devices/system/cpu/cpufreq/boost
LIMIT="$BAT/charge_control_end_threshold"

# sysfs_write ЗНАЧЕНИЕ ФАЙЛ: напрямую → sudo -n → pkexec; иначе явная ошибка
sysfs_write() {
    echo "$1" >"$2" 2>/dev/null && return 0
    echo "$1" | sudo -n tee "$2" >/dev/null 2>&1 && return 0
    echo "$1" | pkexec tee "$2" >/dev/null 2>&1 && return 0
    return 1
}

profile_label() {
    case "$1" in
        performance) printf 'Производительность' ;;
        balanced)    printf 'Баланс' ;;
        power-saver) printf 'Экономия' ;;
        *)           printf '%s' "$1" ;;
    esac
}

human_time() { # "2.3 hours" / "35.0 minutes" → "2ч 18м"
    awk -v n="$1" -v u="$2" 'BEGIN {
        m = (u ~ /hour/) ? n * 60 : (u ~ /day/) ? n * 1440 : n;
        m = int(m + 0.5);
        if (m >= 60) printf "%dч %02dм", m / 60, m % 60; else printf "%dм", m }'
}

battery_rows() {
    [ -n "$BAT" ] || return
    local cap stat info eta health line2
    cap=$(<"$BAT/capacity"); stat=$(<"$BAT/status")
    info=$(upower -i "$(upower -e 2>/dev/null | grep -m1 -i battery)" 2>/dev/null)
    eta=$(awk -F: '/time to (empty|full)/ {gsub(/^[ \t]+/, "", $2); print $2; exit}' <<<"$info")
    health=$(awk -F: '/capacity:/ {gsub(/[ \t%]/, "", $2); printf "%d", $2; exit}' <<<"$info")
    [ -n "$eta" ] && eta="  ·  $(human_time ${eta% *} ${eta#* })"
    ROWS+=("$(bar "$cap")  $(printf '%3d' "$cap")%  BAT  $stat$eta"); KIND+=(none); ARG+=("")
    line2=""
    [ -n "$health" ] && line2="здоровье $health%"
    [ -r "$LIMIT" ] && line2="${line2:+$line2  ·  }лимит заряда $(<"$LIMIT")%"
    [ -n "$line2" ] && { ROWS+=("                          $line2"); KIND+=(none); ARG+=(""); }
}

while true; do
    menu_reset

    battery_rows
    add "──────────────── ПРОФИЛЬ ────────────────" none

    CUR=$(powerprofilesctl get 2>/dev/null)
    mapfile -t PROFILES < <(powerprofilesctl list 2>/dev/null | sed -n 's/^[* ] \([a-z-]*\):.*/\1/p')
    if [ "${#PROFILES[@]}" -eq 0 ]; then
        add "  power-profiles-daemon недоступен" none
    else
        for p in "${PROFILES[@]}"; do
            add "$([ "$p" = "$CUR" ] && echo '●' || echo '○') $(profile_label "$p")  ($p)" profile "$p"
        done
    fi

    if [ -r "$BOOST" ] || [ -r "$LIMIT" ]; then
        add "──────────────── ПАРАМЕТРЫ ──────────────" none
    fi
    if [ -r "$BOOST" ]; then
        if [ "$(<"$BOOST")" = "1" ]; then
            add "⏻ CPU Turbo Boost: ВКЛ  →  выключить" boost 0
        else
            add "⏻ CPU Turbo Boost: ВЫКЛ  →  включить" boost 1
        fi
    fi
    [ -r "$LIMIT" ] && add "⚡ Лимит заряда батареи…" limit

    IDX=$(show_menu "POWER -> " 62 14) || exit 0
    [ -z "$IDX" ] && exit 0

    case "${KIND[IDX]}" in
        profile)
            if powerprofilesctl set "${ARG[IDX]}" 2>/dev/null; then
                notify "Профиль: $(profile_label "${ARG[IDX]}")"
            else
                notify_err "Не удалось сменить профиль (power-profiles-daemon запущен?)"
            fi
            ;;
        boost)
            if sysfs_write "${ARG[IDX]}" "$BOOST"; then
                notify "Turbo Boost: $([ "${ARG[IDX]}" = 1 ] && echo включён || echo выключен)"
            else
                notify_err "Нет прав на запись в $BOOST (нужно sudo без пароля или polkit)"
            fi
            ;;
        limit)
            LV=(60 80 90 100)
            LI=$(printf '%s\n' \
                "60%  — хранение, максимум ресурса" \
                "80%  — работа от розетки (рекомендуется)" \
                "90%  — компромисс" \
                "100% — полный заряд, в дорогу" |
                fz --index --lines 4 --width 50 --prompt "Лимит заряда ($(<"$LIMIT")%) -> ") || continue
            [ -z "$LI" ] && continue
            if sysfs_write "${LV[LI]}" "$LIMIT"; then
                notify "Лимит заряда: ${LV[LI]}% (может сбрасываться после перезагрузки)"
            else
                notify_err "Нет прав на запись в $LIMIT (нужно sudo без пароля или polkit)"
            fi
            ;;
    esac
done
