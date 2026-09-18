#!/usr/bin/env bash

# Проверка доступности контроллера и службы
if ! bluetoothctl show >/dev/null 2>&1; then
    CH=$(printf "1. Запустить bluetooth.service\n2. Отмена" | fuzzel --dmenu --lines 2 --width 38 --prompt="Bluetooth выключен -> ")
    if [[ "$CH" =~ "1" ]]; then
        sudo systemctl start bluetooth.service
        sleep 0.5
        bluetoothctl power on >/dev/null 2>&1
        notify-send "BLUETOOTH" "Служба запущена"
        exec "$0"
    fi
    exit 0
fi

# Проверка питания контроллера
IS_POWERED=$(bluetoothctl show | awk '/Powered:/ {print $2}')
if [ "$IS_POWERED" != "yes" ]; then
    CH=$(printf "1. Включить Bluetooth адаптер\n2. Отмена" | fuzzel --dmenu --lines 2 --width 34 --prompt="Адаптер выключен -> ")
    if [[ "$CH" =~ "1" ]]; then
        bluetoothctl power on >/dev/null 2>&1
        notify-send "BLUETOOTH" "Адаптер включен"
        exec "$0"
    fi
    exit 0
fi

# Списки MAC-адресов
CONNECTED_MACS=$(bluetoothctl devices Connected 2>/dev/null | awk '{print $2}')
PAIRED_MACS=$(bluetoothctl devices Paired 2>/dev/null | awk '{print $2}')

# Сборка меню
MENU_ITEMS=$(bluetoothctl devices 2>/dev/null | awk -v conn="$CONNECTED_MACS" -v paired="$PAIRED_MACS" '
NF >= 3 {
    mac = $2
    name = $3
    for (i=4; i<=NF; i++) name = name " " $i
    if (name == "") next

    is_conn = (conn ~ mac) ? 1 : 0
    is_paired = (paired ~ mac) ? 1 : 0

    if (is_conn) {
        status = "[ПОДКЛЮЧЕНО]"
        active_lines = active_lines sprintf("⏏ Отключить (%s)\n", name)
        active_lines = active_lines sprintf("%-28s │ %-17s │ %s\n", name, mac, status)
    } else if (is_paired) {
        status = "[СОПРЯЖЕНО]"
        paired_lines = paired_lines sprintf("%-28s │ %-17s │ %s\n", name, mac, status)
    } else {
        status = "[НОВОЕ]"
        new_lines = new_lines sprintf("%-28s │ %-17s │ %s\n", name, mac, status)
    }
}
END {
    if (active_lines != "") printf "%s", active_lines
    if (paired_lines != "") printf "%s", paired_lines
    if (new_lines != "") printf "%s", new_lines
    print "────────────────────────────────────────────────────────────"
    print "↺ Поиск новых устройств (5 сек)"
    print "✕ Выключить Bluetooth"
}')

SELECTION=$(echo -e "$MENU_ITEMS" | fuzzel --dmenu --lines 11 --width 64 --prompt="BLUETOOTH -> ")

[ -z "$SELECTION" ] && exit 0

case "$SELECTION" in
    *"Поиск новых устройств"*)
        notify-send "BLUETOOTH" "Сканирование эфира (5 сек)..."
        bluetoothctl --timeout 5 scan on >/dev/null 2>&1
        exec "$0"
        ;;
    *"Выключить Bluetooth"*)
        bluetoothctl power off >/dev/null 2>&1
        notify-send "BLUETOOTH" "Адаптер выключен"
        ;;
    *"⏏ Отключить"*)
        DEV_NAME=$(echo "$SELECTION" | sed -E 's/.*⏏ Отключить \((.*)\).*/\1/')
        MAC=$(bluetoothctl devices Connected 2>/dev/null | grep -F "$DEV_NAME" | awk '{print $2}' | head -n 1)
        if [ -n "$MAC" ]; then
            bluetoothctl disconnect "$MAC" >/dev/null 2>&1
            notify-send "BLUETOOTH" "Отключено: $DEV_NAME"
        fi
        ;;
    *)
        NAME=$(echo "$SELECTION" | cut -d'│' -f1 | xargs)
        MAC=$(echo "$SELECTION" | cut -d'│' -f2 | xargs)
        STATUS=$(echo "$SELECTION" | cut -d'│' -f3 | xargs)

        [ -z "$MAC" ] && exit 0

        if [ "$STATUS" = "[ПОДКЛЮЧЕНО]" ]; then
            bluetoothctl disconnect "$MAC" >/dev/null 2>&1
            notify-send "BLUETOOTH" "Отключено от $NAME"
        elif [ "$STATUS" = "[СОПРЯЖЕНО]" ]; then
            notify-send "BLUETOOTH" "Подключение к $NAME..."
            CONN_OUT=$(bluetoothctl connect "$MAC" 2>&1)
            if echo "$CONN_OUT" | grep -qi "Connection successful"; then
                notify-send "BLUETOOTH" "Подключено к $NAME"
            else
                ERR=$(echo "$CONN_OUT" | grep -i "Failed to connect" | head -n 1)
                [ -z "$ERR" ] && ERR="Сбой подключения к $NAME"
                notify-send -u critical "BLUETOOTH ERROR" "$ERR"
            fi
        else
            # Сопряжение нового устройства
            notify-send "BLUETOOTH" "Сопряжение с $NAME..."
            if bluetoothctl pair "$MAC" >/dev/null 2>&1; then
                bluetoothctl trust "$MAC" >/dev/null 2>&1
                bluetoothctl connect "$MAC" >/dev/null 2>&1
                notify-send "BLUETOOTH" "Устройство $NAME сопряжено и подключено"
            else
                notify-send -u critical "BLUETOOTH ERROR" "Не удалось сопрячь устройство $NAME"
            fi
        fi
        ;;
esac
