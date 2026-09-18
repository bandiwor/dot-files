#!/usr/bin/env bash

MENU=$(cat << 'MENU_END'
1. Lock Screen       [Заблокировать]
2. Suspend           [Спящий режим]
3. Reboot            [Перезагрузка]
4. Power Off         [Выключение]
5. Exit Niri         [Выход из сессии]
MENU_END
)

CH=$(echo -e "$MENU" | fuzzel --dmenu --lines 5 --width 38 --prompt="SESSION [1-5] -> ")
[ -z "$CH" ] && exit 0

case "$CH" in
    1*|*Lock*)
        hyprlock
        ;;
    2*|*Suspend*)
        hyprlock
        sleep 0.2
        systemctl suspend
        ;;
    3*|*Reboot*)
        systemctl reboot
        ;;
    4*|*Power*)
        systemctl poweroff
        ;;
    5*|*Exit*)
        niri msg action quit --skip-confirmation
        ;;
esac
