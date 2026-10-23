#!/usr/bin/env bash
# OSD для аппаратных клавиш: громкость, микрофон, яркость ноутбука.
# Горячий путь (автоповтор клавиши): без awk/seq/subshell-цепочек — разбор вывода wpctl и
# шкала делаются средствами bash. Новое уведомление заменяет предыдущее (synchronous-тег).
#   osd.sh vol-up | vol-down | vol-mute | mic-mute | bright-up | bright-down

_dir=${0%/*}; [ "$_dir" = "$0" ] && _dir=.
. "$_dir/lib/common.sh"

SINK=@DEFAULT_AUDIO_SINK@
SRC=@DEFAULT_AUDIO_SOURCE@
VOL_STEP=5
BRIGHT_STEP=5
BRIGHT_MIN=1   # не даём экрану уйти в чёрный (0%)

# osd ЗАГОЛОВОК ТЕГ ТЕКСТ
osd() { UI_TITLE=$1 UI_TAG=$2 notify "$3" -t 1200; }

# read_vol ЦЕЛЬ → VOL (проценты), MUTED (0/1)
read_vol() {
    local raw v
    raw=$(wpctl get-volume "$1" 2>/dev/null) || { VOL=0; MUTED=0; return 1; }
    v=${raw#Volume: }; v=${v%% *}
    VOL=$((10#${v/./}))
    [[ $raw == *MUTED* ]] && MUTED=1 || MUTED=0
}

show_volume() {
    read_vol "$SINK"
    if [ "$MUTED" = 1 ]; then
        osd VOLUME volume "$(bar "$VOL")  ${VOL}%  [MUTED]"
    else
        osd VOLUME volume "$(bar "$VOL")  ${VOL}%"
    fi
}

# Меняем яркость на шаг с нижней границей; -m выдаёт итоговое значение сразу
bright_step() {
    local cur new out
    cur=$(brightnessctl -m 2>/dev/null | cut -d, -f4)
    cur=${cur%\%}
    [ -z "$cur" ] && { notify_err "Подсветка недоступна"; return 1; }
    new=$(clamp $(( cur + $1 )) "$BRIGHT_MIN" 100)
    out=$(brightnessctl -m set "${new}%" 2>/dev/null | cut -d, -f4)
    out=${out%\%}
    osd BRIGHTNESS brightness "$(bar "${out:-$new}")  ${out:-$new}%"
}

case "${1:-}" in
    vol-up)
        wpctl set-mute "$SINK" 0
        wpctl set-volume -l 1.25 "$SINK" "${VOL_STEP}%+"
        show_volume
        ;;
    vol-down)
        wpctl set-mute "$SINK" 0
        wpctl set-volume "$SINK" "${VOL_STEP}%-"
        show_volume
        ;;
    vol-mute)
        wpctl set-mute "$SINK" toggle
        read_vol "$SINK"
        if [ "$MUTED" = 1 ]; then
            osd VOLUME volume "Звук выключен  [MUTED]"
        else
            osd VOLUME volume "$(bar "$VOL")  ${VOL}%"
        fi
        ;;
    mic-mute)
        wpctl set-mute "$SRC" toggle
        read_vol "$SRC"
        if [ "$MUTED" = 1 ]; then
            osd MICROPHONE mic "Микрофон заглушен  [MUTED]"
        else
            osd MICROPHONE mic "Микрофон активен  [LIVE]"
        fi
        ;;
    bright-up)   bright_step "$BRIGHT_STEP" ;;
    bright-down) bright_step "-$BRIGHT_STEP" ;;
    *)
        echo "usage: ${0##*/} vol-up|vol-down|vol-mute|mic-mute|bright-up|bright-down" >&2
        exit 2
        ;;
esac
