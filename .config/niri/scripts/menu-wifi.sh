#!/usr/bin/env bash
# Wi-Fi хаб (Mod+N → 1): nmcli + fuzzel.
# Открывается мгновенно: список берётся из кэша NM (--rescan no), свежий скан идёт фоном.
# Выбор строки по индексу (fuzzel --index), а не разбором текста — SSID с любыми символами безопасны.

fz() { fuzzel --dmenu "$@"; }

notify()     { notify-send -h string:x-canonical-private-synchronous:wifi-hub "NETWORK" "$1"; }
notify_err() { notify-send -u critical -h string:x-canonical-private-synchronous:wifi-hub "NETWORK ERROR" "$1"; }

WLAN_IF=$(nmcli -t -f DEVICE,TYPE dev status 2>/dev/null | awk -F: '$2=="wifi"{print $1; exit}')
if [ -z "$WLAN_IF" ]; then
    notify_err "Wi-Fi адаптер не найден"
    exit 1
fi

declare -A SAVED
load_saved() {
    SAVED=()
    local n
    while IFS= read -r n; do
        [ -n "$n" ] && SAVED["$n"]=1
    done < <(nmcli -t --escape no -f TYPE,NAME connection show 2>/dev/null |
        awk -F: '$1=="802-11-wireless"{sub(/^[^:]*:/, ""); print}')
}

bars() {
    if   [ "$1" -gt 75 ]; then printf '████'
    elif [ "$1" -gt 50 ]; then printf '███░'
    elif [ "$1" -gt 25 ]; then printf '██░░'
    else                       printf '█░░░'
    fi
}

band() {
    local mhz=${1%% *}
    if   [ "${mhz:-0}" -ge 5900 ]; then printf '6G'
    elif [ "${mhz:-0}" -ge 3000 ]; then printf '5G'
    else                                printf '2.4G'
    fi
}

sec_label() {
    case "$1" in
        ""|"--")  printf 'OPEN' ;;
        *802.1X*) printf 'EAP'  ;;
        *WPA3*)   printf 'WPA3' ;;
        *WPA*)    printf 'WPA2' ;;
        *WEP*)    printf 'WEP'  ;;
        *)        printf 'SEC'  ;;
    esac
}

is_auth_error() { grep -qiE 'secret|password|psk|handshake|deauth|disassoc|authenticat' <<<"$1"; }

first_error() {
    local e
    e=$(grep -i 'error' <<<"$1" | head -n 1 | sed 's/^Error: //')
    printf '%s' "${e:-Ошибка подключения}"
}

# Запрос пароля и подключение. Старый профиль удаляется только после ввода нового
# пароля — отмена (Esc) ничего не ломает.
ask_and_connect() {
    local ssid=$1 hint=${2:-} pass out
    while true; do
        pass=$(fz --password --lines 0 --width 52 --prompt "${hint}Пароль для $ssid -> " </dev/null) || return 1
        [ -z "$pass" ] && return 1

        [ -n "${SAVED[$ssid]:-}" ] && nmcli connection delete id "$ssid" >/dev/null 2>&1
        notify "Подключение к $ssid..."
        if out=$(nmcli -w 25 dev wifi connect "$ssid" password "$pass" 2>&1); then
            notify "Подключено к $ssid"
            return 0
        fi
        # Профиль только что создан этой попыткой — убираем, чтобы NM не кэшировал неверный ключ
        nmcli connection delete id "$ssid" >/dev/null 2>&1 || true

        if is_auth_error "$out"; then
            notify_err "Неверный пароль для '$ssid'"
            hint="[НЕВЕРНЫЙ ПАРОЛЬ] "
        else
            notify_err "$(first_error "$out")"
            hint="[ОШИБКА] "
        fi
    done
}

connect_network() {
    local ssid=$1 sec=$2 out

    if [ -n "${SAVED[$ssid]:-}" ]; then
        notify "Подключение к $ssid..."
        if out=$(nmcli -w 20 connection up id "$ssid" 2>&1); then
            notify "Подключено к $ssid"
            return 0
        fi
        # Сохранённый профиль не трогаем: сбой может быть из-за слабого сигнала или таймаута
        if is_auth_error "$out"; then
            notify_err "Сохранённый пароль для '$ssid' не подошёл"
            ask_and_connect "$ssid" "[ПАРОЛЬ УСТАРЕЛ] "
            return
        fi
        notify_err "$(first_error "$out")"
        return 1
    fi

    case "$sec" in
        "")
            notify "Подключение к $ssid..."
            if out=$(nmcli -w 20 dev wifi connect "$ssid" 2>&1); then
                notify "Подключено к открытой сети $ssid"
                return 0
            fi
            notify_err "$(first_error "$out")"
            return 1
            ;;
        *802.1X*)
            notify_err "'$ssid' — корпоративная сеть (802.1X). Настрой профиль через nm-connection-editor"
            return 1
            ;;
        *)
            ask_and_connect "$ssid"
            ;;
    esac
}

connect_hidden() {
    local ssid pass out
    local -a args
    ssid=$(fz --lines 0 --width 44 --prompt "Скрытая сеть, SSID -> " </dev/null) || return 1
    [ -z "$ssid" ] && return 1
    pass=$(fz --password --lines 0 --width 52 --prompt "Пароль (пусто = открытая) -> " </dev/null) || return 1

    args=(-w 25 dev wifi connect "$ssid" hidden yes)
    [ -n "$pass" ] && args+=(password "$pass")

    notify "Подключение к $ssid..."
    if out=$(nmcli "${args[@]}" 2>&1); then
        notify "Подключено к $ssid"
        return 0
    fi
    nmcli connection delete id "$ssid" >/dev/null 2>&1 || true
    notify_err "$(first_error "$out")"
    return 1
}

forget_menu() {
    local -a names
    local idx
    mapfile -t names < <(printf '%s\n' "${!SAVED[@]}" | sort -f)
    [ "${#names[@]}" -eq 0 ] && return 0

    idx=$(printf '%s\n' "${names[@]}" |
        fz --index --lines "$(( ${#names[@]} > 10 ? 10 : ${#names[@]} ))" --width 48 --prompt "ЗАБЫТЬ СЕТЬ -> ") || return 0
    [ -z "$idx" ] && return 0

    if nmcli connection delete id "${names[idx]}" >/dev/null 2>&1; then
        notify "Профиль удалён: ${names[idx]}"
    else
        notify_err "Не удалось удалить профиль ${names[idx]}"
    fi
}

# Подменю активной сети: защищает от случайного Enter на первой строке
active_menu() {
    local ssid=$1 idx
    idx=$(printf '%s\n' "⏏ Отключиться" "✕ Забыть сеть" "← Назад" |
        fz --index --lines 3 --width 36 --prompt "$ssid -> ") || return 1
    case "$idx" in
        0)
            nmcli dev disconnect "$WLAN_IF" >/dev/null 2>&1
            notify "Отключено от $ssid"
            return 0
            ;;
        1)
            if nmcli connection delete id "$ssid" >/dev/null 2>&1; then
                notify "Профиль удалён, отключено от $ssid"
            else
                notify_err "Не удалось забыть сеть $ssid"
            fi
            return 0
            ;;
    esac
    return 1
}

scanned=""
while true; do
    if [ "$(nmcli radio wifi 2>/dev/null)" != "enabled" ]; then
        CH=$(printf '%s\n' "Включить Wi-Fi" "Отмена" |
            fz --index --lines 2 --width 32 --prompt "Wi-Fi выключен -> ") || exit 0
        [ "$CH" = "0" ] || exit 0
        nmcli radio wifi on && notify "Адаптер Wi-Fi включен"
        sleep 2
        continue
    fi

    load_saved
    nmcli dev wifi rescan >/dev/null 2>&1 &

    # Активные сети первыми (IN-USE='*'), дальше по убыванию сигнала
    mapfile -t NETS < <(nmcli -t --escape no -f IN-USE,SIGNAL,SECURITY,FREQ,SSID dev wifi list --rescan no 2>/dev/null |
        LC_ALL=C sort -t: -k1,1r -k2,2nr)

    ROWS=() KIND=() ARG=() SEC=()
    declare -A SEEN=()
    ACTIVE=""
    for line in "${NETS[@]}"; do
        IFS=: read -r inuse sig sec freq ssid <<<"$line"
        { [ -z "$ssid" ] || [ "$ssid" = "--" ]; } && continue
        [ -n "${SEEN[$ssid]:-}" ] && continue
        SEEN["$ssid"]=1

        extra=""
        if [ "$inuse" = "*" ]; then
            ACTIVE=$ssid
            mark="●"
            IP=$(nmcli -g IP4.ADDRESS dev show "$WLAN_IF" 2>/dev/null | head -n 1)
            [ -n "$IP" ] && extra="   ${IP%%[/|]*}"
        elif [ -n "${SAVED[$ssid]:-}" ]; then
            mark="○"
        else
            mark=" "
        fi

        s=$(sec_label "$sec")
        ROWS+=("$(printf '%s %s %-4s %-4s  %s%s' "$mark" "$(bars "${sig:-0}")" "$s" "$(band "$freq")" "$ssid" "$extra")")
        if [ "$inuse" = "*" ]; then KIND+=("active"); else KIND+=("net"); fi
        ARG+=("$ssid")
        if [ "$s" = "OPEN" ]; then SEC+=(""); else SEC+=("$sec"); fi
    done

    # Кэш пуст (например, адаптер только включили) — один раз сканируем синхронно
    if [ "${#ROWS[@]}" -eq 0 ] && [ -z "$scanned" ]; then
        scanned=1
        notify "Сканирование сетей..."
        nmcli dev wifi rescan >/dev/null 2>&1
        sleep 2
        continue
    fi

    ROWS+=("────────────────────────────────────────────")
    KIND+=("none"); ARG+=(""); SEC+=("")
    ROWS+=("↺ Пересканировать эфир");        KIND+=("rescan");  ARG+=(""); SEC+=("")
    ROWS+=("⌕ Скрытая сеть…");               KIND+=("hidden");  ARG+=(""); SEC+=("")
    if [ "${#SAVED[@]}" -gt 0 ]; then
        ROWS+=("✕ Забыть сохранённую сеть…"); KIND+=("forget"); ARG+=(""); SEC+=("")
    fi
    ROWS+=("⏻ Выключить Wi-Fi");            KIND+=("off");     ARG+=(""); SEC+=("")

    VISIBLE=${#ROWS[@]}
    [ "$VISIBLE" -gt 12 ] && VISIBLE=12

    IDX=$(printf '%s\n' "${ROWS[@]}" |
        fz --index --lines "$VISIBLE" --width 62 --prompt "WI-FI -> ") || exit 0
    [ -z "$IDX" ] && exit 0

    case "${KIND[IDX]}" in
        active) active_menu "${ARG[IDX]}" && exit 0 ;;
        net)    connect_network "${ARG[IDX]}" "${SEC[IDX]}" && exit 0 ;;
        hidden) connect_hidden && exit 0 ;;
        forget) forget_menu ;;
        rescan)
            notify "Сканирование доступных сетей..."
            nmcli dev wifi rescan >/dev/null 2>&1
            sleep 2
            ;;
        off)
            nmcli radio wifi off
            notify "Wi-Fi адаптер отключен"
            exit 0
            ;;
    esac
done
