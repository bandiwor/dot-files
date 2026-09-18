#!/usr/bin/env bash

CH=$(printf "1. Wi-Fi Эфир\n2. Bluetooth Устройства" | fuzzel --dmenu --lines 2 --width 28 --prompt="WIRELESS [1/2] -> ")

case "$CH" in
    1*|*"Wi-Fi"*)
        exec "$HOME/.config/niri/scripts/menu-wifi.sh"
        ;;
    2*|*"Bluetooth"*)
        exec "$HOME/.config/niri/scripts/menu-bluetooth.sh"
        ;;
    *)
        exit 0
        ;;
esac
