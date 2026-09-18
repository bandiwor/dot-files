#!/usr/bin/env bash

# Имя Wi-Fi интерфейса (например, wlp1s0)
WLAN_IF=$(nmcli -t -f DEVICE,TYPE dev status 2>/dev/null | awk -F: '$2=="wifi"{print $1; exit}')

WIFI_STATUS=$(nmcli -t -f WIFI g 2>/dev/null)

if [ "$WIFI_STATUS" = "disabled" ]; then
    CH=$(printf "1. Включить Wi-Fi\n2. Отмена" | fuzzel --dmenu --lines 2 --width 32 --prompt="Wi-Fi выключен -> ")
    [[ "$CH" =~ "1" ]] && nmcli radio wifi on && notify-send "NETWORK" "Адаптер Wi-Fi включен"
    exit 0
fi

# Определение активного подключения
ACTIVE_SSID=$(nmcli -t -f IN-USE,SSID dev wifi list 2>/dev/null | awk -F: '$1=="*"{print $2; exit}')
if [ -z "$ACTIVE_SSID" ] && [ -n "$WLAN_IF" ]; then
    ACTIVE_SSID=$(nmcli -t -f GENERAL.CONNECTION dev show "$WLAN_IF" 2>/dev/null | awk -F: '$2 != "" && $2 != "--" {print $2; exit}')
fi

# Генерация таблицы сетей
MENU_ITEMS=$(nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID dev wifi list 2>/dev/null | awk -F: -v active_ssid="$ACTIVE_SSID" '
NF >= 4 {
    in_use = $1
    sig = $2
    sec = ($3 == "") ? "OPEN" : "SEC"
    ssid = $4
    for (i=5; i<=NF; i++) ssid = ssid ":" $i
    gsub(/\\:/, ":", ssid)
    if (ssid == "" || ssid == "--") next

    bars = (sig > 75) ? "[████]" : (sig > 50) ? "[███░]" : (sig > 25) ? "[██░░]" : "[█░░░]"

    if (in_use == "*") {
        active_line = sprintf("%-28s │ %-6s │ %-6s │ %s", ssid, bars, sec, "[ПОДКЛЮЧЕНО]")
    } else {
        if (!seen[ssid]++) {
            list = list sprintf("%-28s │ %-6s │ %-6s\n", ssid, bars, sec)
        }
    }
}
END {
    if (active_ssid != "") {
        printf "⏏ Отключиться от сети (%s)\n", active_ssid
    }
    if (active_line != "") print active_line
    printf "%s", list
    print "────────────────────────────────────────────────────────────"
    print "↺ Пересканировать эфир"
    print "✕ Выключить Wi-Fi"
}')

SELECTION=$(echo -e "$MENU_ITEMS" | fuzzel --dmenu --lines 11 --width 64 --prompt="WI-FI ЭФИР -> ")

[ -z "$SELECTION" ] && exit 0

case "$SELECTION" in
    *"Пересканировать"*)
        nmcli dev wifi rescan
        notify-send "NETWORK" "Сканирование доступных сетей..."
        exec "$0"
        ;;
    *"Выключить"*)
        nmcli radio wifi off
        notify-send "NETWORK" "Wi-Fi адаптер отключен"
        ;;
    *"Отключиться"*|*"[ПОДКЛЮЧЕНО]"*)
        if [ -n "$WLAN_IF" ]; then
            nmcli dev disconnect "$WLAN_IF" >/dev/null 2>&1
        fi
        [ -n "$ACTIVE_SSID" ] && nmcli con down id "$ACTIVE_SSID" >/dev/null 2>&1
        notify-send "NETWORK" "Отключено от ${ACTIVE_SSID:-сети}"
        ;;
    *)
        SSID=$(echo "$SELECTION" | cut -d'│' -f1 | xargs)
        [ -z "$SSID" ] && exit 0

        # Проверка наличия сохраненного профиля
        KNOWN=$(nmcli -t -f NAME connection show | grep -Fx "$SSID" || true)

        if [ -n "$KNOWN" ]; then
            notify-send "NETWORK" "Подключение к $SSID..."
            if nmcli connection up id "$SSID" >/dev/null 2>&1; then
                notify-send "NETWORK" "Подключено к $SSID"
                exit 0
            else
                # Если роутер отклонил сохраненный ключ (сменился пароль)
                nmcli connection delete id "$SSID" >/dev/null 2>&1 || true
                notify-send -u critical "NETWORK ERROR" "Сбой авторизации $SSID. Введите пароль повторно."
                PROMPT_MSG="[СБОЙ КЛЮЧА] Пароль для $SSID -> "
            fi
        fi

        SEC=$(echo "$SELECTION" | cut -d'│' -f3 | xargs)
        if [ "$SEC" = "OPEN" ]; then
            notify-send "NETWORK" "Подключение к $SSID..."
            if nmcli dev wifi connect "$SSID" >/dev/null 2>&1; then
                notify-send "NETWORK" "Подключено к открытой сети $SSID"
            else
                notify-send -u critical "NETWORK ERROR" "Не удалось подключиться к $SSID"
            fi
            exit 0
        fi

        # Цикл запроса пароля с возможностью повторного ввода
        PROMPT_MSG="${PROMPT_MSG:-Пароль для $SSID -> }"
        while true; do
            PASS=$(fuzzel --dmenu --password --width 52 --prompt="$PROMPT_MSG") || exit 0
            [ -z "$PASS" ] && exit 0

            notify-send "NETWORK" "Подключение к $SSID..."
            CONN_OUT=$(nmcli dev wifi connect "$SSID" password "$PASS" 2>&1)
            CONN_STAT=$?

            if [ $CONN_STAT -eq 0 ]; then
                notify-send "NETWORK" "Подключено к $SSID"
                break
            else
                # Очищаем битый профиль, чтобы NM не кэшировал неверный ключ
                nmcli connection delete id "$SSID" >/dev/null 2>&1 || true

                if echo "$CONN_OUT" | grep -qiE "secret|password|handshake|key|psk|deauth|disassoc"; then
                    notify-send -u critical "NETWORK ERROR" "Неверный пароль для сети '$SSID'"
                    PROMPT_MSG="[НЕВЕРНЫЙ ПАРОЛЬ] Пароль для $SSID -> "
                else
                    ERR_MSG=$(echo "$CONN_OUT" | grep -i "Error:" | sed 's/Error: //' | head -n 1)
                    [ -z "$ERR_MSG" ] && ERR_MSG="Ошибка подключения"
                    notify-send -u critical "NETWORK ERROR" "$ERR_MSG"
                    PROMPT_MSG="[ОШИБКА] Пароль для $SSID -> "
                fi
            fi
        done
        ;;
esac
