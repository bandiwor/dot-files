#!/bin/sh

mkdir -p "$HOME/Pictures"

FILENAME="$(date +'%Y-%m-%d-%H%M%S_shot.png')"
FILE="$HOME/Pictures/$FILENAME"

if [ "$1" = "area" ]; then
    GEOM=$(slurp) || exit 1
    grim -g "$GEOM" "$FILE"
else
    grim "$FILE"
fi

if [ -f "$FILE" ]; then
    wl-copy -t image/png < "$FILE"
    
    notify-send "Shot!" "Сохранено в ~/Pictures/$FILENAME" -i "$FILE"
fi
