#!/usr/bin/env bash
# Медиа-клавиши и меню плеера (playerctl).
#   media.sh play-pause | next | previous | stop   — действие + OSD
#   media.sh                                        — меню
# Состояние читается одним вызовом playerctl; вместо фиксированных sleep —
# короткий опрос, пока плеер реально не сменит трек/статус.

UI_TITLE=MEDIA UI_TAG=media
_dir=${0%/*}; [ "$_dir" = "$0" ] && _dir=.
. "$_dir/lib/common.sh"

if ! command -v playerctl >/dev/null 2>&1; then
    notify_err "playerctl не установлен (pacman -S playerctl)"
    exit 1
fi

SEP=$'\x1f'

# read_state → STATUS, ARTIST, TITLE (пусто, если плеера нет)
read_state() {
    STATUS="" ARTIST="" TITLE=""
    IFS=$SEP read -r STATUS ARTIST TITLE < <(
        playerctl metadata --format "{{status}}${SEP}{{artist}}${SEP}{{title}}" 2>/dev/null)
    if [ -z "$STATUS" ]; then
        STATUS=$(playerctl status 2>/dev/null)
    fi
}

now_playing() {
    if [ -n "$TITLE" ] && [ -n "$ARTIST" ]; then printf '%s — %s' "$TITLE" "$ARTIST"
    elif [ -n "$TITLE" ]; then printf '%s' "$TITLE"
    else printf 'Статус: %s' "$STATUS"
    fi
}

show_osd() {
    if [ -z "$STATUS" ]; then
        UI_TITLE=MEDIA notify "Нет активных медиаплееров" -t 1500
        return
    fi
    local tag
    case "$STATUS" in
        Playing) tag="[PLAYING]" ;;
        Paused)  tag="[PAUSED]" ;;
        Stopped) tag="[STOPPED]" ;;
        *)       tag="[$STATUS]" ;;
    esac
    UI_TITLE="MEDIA $tag" notify "$(now_playing)" -t 2000
}

# do_action ДЕЙСТВИЕ — выполняет и ждёт видимого результата (до ~0.5 с)
do_action() {
    local action=$1 before_status before_title i
    read_state
    before_status=$STATUS before_title=$TITLE
    if [ -z "$STATUS" ]; then show_osd; return; fi

    playerctl "$action" 2>/dev/null

    for i in {1..10}; do
        read_state
        case "$action" in
            next|previous) [ "$TITLE" != "$before_title" ] && break ;;
            *)             [ "$STATUS" != "$before_status" ] && break ;;
        esac
        sleep 0.05
    done
    show_osd
}

ACTION=${1:-}

if [ -z "$ACTION" ]; then
    read_state
    HEADER="MEDIA"
    [ -n "$TITLE" ] && HEADER="${TITLE:0:30}${ARTIST:+ — ${ARTIST:0:16}}"
    menu_reset
    add "⏯ Play / Pause"  play-pause
    add "⏭ Следующий"     next
    add "⏮ Предыдущий"    previous
    add "⏹ Стоп"          stop
    IDX=$(show_menu "$HEADER -> " 50) || exit 0
    [ -z "$IDX" ] && exit 0
    ACTION=${KIND[IDX]}
fi

case "$ACTION" in
    play-pause|toggle) do_action play-pause ;;
    next)              do_action next ;;
    previous|prev)     do_action previous ;;
    stop)              do_action stop ;;
    *) echo "usage: ${0##*/} play-pause|next|previous|stop" >&2; exit 2 ;;
esac
