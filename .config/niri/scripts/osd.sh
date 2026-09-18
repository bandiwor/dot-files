#!/usr/bin/env bash

make_bar() {
    local val=${1:-0}
    local total=10
    local filled=$(( (val + 5) / 10 ))
    [ "$filled" -gt 10 ] && filled=10
    [ "$filled" -lt 0 ] && filled=0
    local empty=$(( total - filled ))
    printf "[%s%s] %3d%%" "$(printf '█%.0s' $(seq 1 $filled 2>/dev/null))" "$(printf '░%.0s' $(seq 1 $empty 2>/dev/null))" "$val"
}

case "$1" in
    vol-up)
        wpctl set-volume -l 1.25 @DEFAULT_AUDIO_SINK@ 5%+
        RAW=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
        VOL=$(echo "$RAW" | awk '{print int($2 * 100)}')
        if echo "$RAW" | grep -q "MUTED"; then
            notify-send -r 9991 -t 1200 -h string:synchronous:volume "VOLUME" "[MUTED] $(make_bar "$VOL")"
        else
            notify-send -r 9991 -t 1200 -h string:synchronous:volume "VOLUME" "$(make_bar "$VOL")"
        fi
        ;;
    vol-down)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        RAW=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
        VOL=$(echo "$RAW" | awk '{print int($2 * 100)}')
        if echo "$RAW" | grep -q "MUTED"; then
            notify-send -r 9991 -t 1200 -h string:synchronous:volume "VOLUME" "[MUTED] $(make_bar "$VOL")"
        else
            notify-send -r 9991 -t 1200 -h string:synchronous:volume "VOLUME" "$(make_bar "$VOL")"
        fi
        ;;
    vol-mute)
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        RAW=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
        VOL=$(echo "$RAW" | awk '{print int($2 * 100)}')
        if echo "$RAW" | grep -q "MUTED"; then
            notify-send -r 9991 -t 1200 -h string:synchronous:volume "VOLUME" "Звук выключен [MUTED]"
        else
            notify-send -r 9991 -t 1200 -h string:synchronous:volume "VOLUME" "Звук включен $(make_bar "$VOL")"
        fi
        ;;
    mic-mute)
        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
        RAW=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null)
        if echo "$RAW" | grep -q "MUTED"; then
            notify-send -r 9992 -t 1200 -h string:synchronous:mic "MICROPHONE" "Микрофон заглушен [MUTED]"
        else
            notify-send -r 9992 -t 1200 -h string:synchronous:mic "MICROPHONE" "Микрофон активен [UNMUTED]"
        fi
        ;;
    bright-up)
        brightnessctl set 5%+ >/dev/null
        BR=$(brightnessctl -m 2>/dev/null | awk -F, '{print sub(/%/, "", $4) ? $4 : $4}')
        notify-send -r 9993 -t 1200 -h string:synchronous:bright "BRIGHTNESS" "$(make_bar "$BR")"
        ;;
    bright-down)
        brightnessctl set 5%- >/dev/null
        BR=$(brightnessctl -m 2>/dev/null | awk -F, '{print sub(/%/, "", $4) ? $4 : $4}')
        notify-send -r 9993 -t 1200 -h string:synchronous:bright "BRIGHTNESS" "$(make_bar "$BR")"
        ;;
esac
