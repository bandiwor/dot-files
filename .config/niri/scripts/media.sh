#!/usr/bin/env bash

send_osd() {
    local action="$1"
    local status=""
    local title=""
    local artist=""

    # При смене трека ждем, пока плеер начнет воспроизведение и отдаст название
    if [ "$action" = "next" ] || [ "$action" = "prev" ]; then
        for _ in {1..10}; do
            sleep 0.05
            status=$(playerctl status 2>/dev/null)
            title=$(playerctl metadata title 2>/dev/null)
            artist=$(playerctl metadata artist 2>/dev/null)
            if [ "$status" = "Playing" ] && [ -n "$title" ]; then
                break
            fi
        done
    else
        sleep 0.08
        status=$(playerctl status 2>/dev/null)
        title=$(playerctl metadata title 2>/dev/null)
        artist=$(playerctl metadata artist 2>/dev/null)
    fi

    if [ -z "$status" ]; then
        notify-send -r 9994 -t 1500 -h string:synchronous:media "MEDIA" "Нет активных медиаплееров"
        return
    fi

    [ "$status" = "Playing" ] && TAG="[PLAYING]"
    [ "$status" = "Paused" ]  && TAG="[PAUSED]"
    [ "$status" = "Stopped" ] && TAG="[STOPPED]"

    if [ -n "$title" ] && [ -n "$artist" ]; then
        BODY="${title} — ${artist}"
    elif [ -n "$title" ]; then
        BODY="${title}"
    else
        BODY="Статус: ${status}"
    fi

    notify-send -r 9994 -t 2000 -h string:synchronous:media "MEDIA ${TAG}" "$BODY"
}

ACTION="$1"

if [ -z "$ACTION" ]; then
    STATUS=$(playerctl status 2>/dev/null || echo "Inactive")
    TITLE=$(playerctl metadata title 2>/dev/null || echo "Нет трека")
    ARTIST=$(playerctl metadata artist 2>/dev/null)
    [ -n "$ARTIST" ] && HEADER="${TITLE:0:26} — ${ARTIST:0:16}" || HEADER="${TITLE:0:36}"

    MENU=$(cat << 'MENU_END'
1. Play / Pause  [Toggle]
2. Next Track    [Вперед]
3. Prev Track    [Назад]
4. Stop          [Стоп]
MENU_END
)
    CH=$(echo -e "$MENU" | fuzzel --dmenu --lines 4 --width 50 --prompt="$HEADER -> ")
    [ -z "$CH" ] && exit 0

    case "$CH" in
        1*|*Play*) ACTION="play-pause" ;;
        2*|*Next*) ACTION="next" ;;
        3*|*Prev*) ACTION="previous" ;;
        4*|*Stop*) ACTION="stop" ;;
    esac
fi

case "$ACTION" in
    play-pause|toggle)
        playerctl play-pause 2>/dev/null
        send_osd "play-pause"
        ;;
    next)
        playerctl next 2>/dev/null
        send_osd "next"
        ;;
    previous|prev)
        playerctl previous 2>/dev/null
        send_osd "prev"
        ;;
    stop)
        playerctl stop 2>/dev/null
        send_osd "stop"
        ;;
esac
