#!/usr/bin/env bash
set -euo pipefail

case "${1:-menu}" in
    menu)
        SELECTED=$(cliphist list | fuzzel --dmenu --lines 10 --width 64 --prompt="CLIPBOARD > ")
        [ -z "$SELECTED" ] && exit 0

        # Проверяем, является ли выбранный элемент изображением
        if [[ "$SELECTED" =~ \[\[\ binary\ data ]]; then
            case "$SELECTED" in
                *jpg*|*jpeg*) MIME="image/jpeg" ;;
                *webp*)       MIME="image/webp" ;;
                *)            MIME="image/png" ;;
            esac

            printf '%s\n' "$SELECTED" | cliphist decode | wl-copy --type "$MIME"
            notify-send -r 9995 -t 1000 -h string:synchronous:clip "CLIPBOARD" "Изображение ($MIME)"
        else
            printf '%s\n' "$SELECTED" | cliphist decode | wl-copy
            notify-send -r 9995 -t 1000 -h string:synchronous:clip "CLIPBOARD" "Текст скопирован"
        fi
        ;;
    wipe)
        cliphist wipe
        notify-send -r 9995 -t 1000 -h string:synchronous:clip "CLIPBOARD" "История буфера очищена"
        ;;
esac
