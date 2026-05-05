#!/bin/sh

FILENAME="$(date +'%Y-%m-%d-%H%M%S_shot.png')"
FILE="$HOME/Pictures/$FILENAME"

if [ "$1" = "area" ]; then
    GEOM=$(slurp) || exit 1
    grim -g "$GEOM" "$FILE"
else
    grim "$FILE"
fi

sleep 0.1

if [ -f "$FILE" ]; then
    echo -n "file://$FILE" | wl-copy -t text/uri-list
    
    notify-send "Shot!" " ~/Pictures/$FILENAME" -i "$FILE"
fi
