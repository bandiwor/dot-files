#!/usr/bin/env bash
# Bluetooth хаб (Mod+N → 2): bluetoothctl + fuzzel.
# Список мгновенный (кэш bluez), поиск новых устройств идёт фоном.
# Выбор по индексу (fuzzel --index), имена устройств не парсятся из текста.

fz() { fuzzel --dmenu "$@"; }

notify()     { notify-send -h string:x-canonical-private-synchronous:bt-hub "BLUETOOTH" "$1"; }
notify_err() { notify-send -u critical -h string:x-canonical-private-synchronous:bt-hub "BLUETOOTH ERROR" "$1"; }

MAC_RE='^([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}$'

# Служба не запущена / нет контроллера
ensure_service() {
    bluetoothctl show >/dev/null 2>&1 && return 0
    local ch
    ch=$(printf '%s\n' "Запустить bluetooth.service" "Отмена" |
        fz --index --lines 2 --width 38 --prompt "Bluetooth недоступен -> ") || return 1
    [ "$ch" = "0" ] || return 1
    systemctl start bluetooth.service 2>/dev/null || sudo -n systemctl start bluetooth.service 2>/dev/null
    sleep 0.5
    bluetoothctl power on >/dev/null 2>&1
    bluetoothctl show >/dev/null 2>&1 && notify "Служба запущена" && return 0
    notify_err "Не удалось запустить bluetooth.service"
    return 1
}

ensure_power() {
    [ "$(bluetoothctl show 2>/dev/null | awk '/Powered:/ {print $2}')" = "yes" ] && return 0
    local ch
    ch=$(printf '%s\n' "Включить Bluetooth" "Отмена" |
        fz --index --lines 2 --width 34 --prompt "Адаптер выключен -> ") || return 1
    [ "$ch" = "0" ] || return 1
    bluetoothctl power on >/dev/null 2>&1
    notify "Адаптер включен"
    sleep 1
    return 0
}

battery_of() {
    bluetoothctl info "$1" 2>/dev/null | sed -n 's/.*Battery Percentage:.*(\([0-9]*\)).*/\1/p' | head -n 1
}

# Подключение/сопряжение; 0 — успех
connect_device() {
    local mac=$1 name=$2 state=$3 out
    if [ "$state" = "new" ]; then
        notify "Сопряжение с $name..."
        if ! timeout 40 bluetoothctl pair "$mac" >/dev/null 2>&1; then
            notify_err "Не удалось сопрячь $name"
            return 1
        fi
        bluetoothctl trust "$mac" >/dev/null 2>&1
    fi
    notify "Подключение к $name..."
    out=$(timeout 25 bluetoothctl connect "$mac" 2>&1)
    if grep -qi 'Connection successful' <<<"$out"; then
        notify "Подключено: $name"
        return 0
    fi
    local err
    err=$(grep -i 'Failed' <<<"$out" | head -n 1)
    notify_err "${err:-Сбой подключения к $name}"
    return 1
}

# Подменю подключённого устройства: защита от случайного Enter
active_menu() {
    local mac=$1 name=$2 idx
    idx=$(printf '%s\n' "⏏ Отключиться" "✕ Забыть устройство" "← Назад" |
        fz --index --lines 3 --width 40 --prompt "$name -> ") || return 1
    case "$idx" in
        0) bluetoothctl disconnect "$mac" >/dev/null 2>&1; notify "Отключено: $name"; return 0 ;;
        1) bluetoothctl remove "$mac" >/dev/null 2>&1;     notify "Устройство забыто: $name"; return 0 ;;
    esac
    return 1
}

forget_menu() {
    local -n _macs=$1 _names=$2
    [ "${#_macs[@]}" -eq 0 ] && return 0
    local idx
    idx=$(printf '%s\n' "${_names[@]}" |
        fz --index --lines "$(( ${#_names[@]} > 10 ? 10 : ${#_names[@]} ))" --width 48 --prompt "ЗАБЫТЬ УСТРОЙСТВО -> ") || return 0
    [ -z "$idx" ] && return 0
    bluetoothctl remove "${_macs[idx]}" >/dev/null 2>&1 && notify "Устройство забыто: ${_names[idx]}"
}

ensure_service || exit 0
scanned=""

while true; do
    ensure_power || exit 0

    # Фоновый поиск: результаты появятся при следующем открытии/пересканировании
    ( bluetoothctl --timeout 6 scan on >/dev/null 2>&1 & )

    declare -A CONN=() PAIR=()
    while read -r _ mac _; do [ -n "$mac" ] && CONN["$mac"]=1; done < <(bluetoothctl devices Connected 2>/dev/null)
    while read -r _ mac _; do [ -n "$mac" ] && PAIR["$mac"]=1; done < <(bluetoothctl devices Paired 2>/dev/null)

    # Группы: подключённые, сопряжённые, новые (устройства без имени — шум, скрываем)
    C_ROWS=() C_MAC=() C_NAME=()
    P_ROWS=() P_MAC=() P_NAME=()
    N_ROWS=() N_MAC=() N_NAME=()
    while read -r _ mac name; do
        [ -z "$mac" ] && continue
        [ -z "$name" ] && continue
        [[ "$name" =~ $MAC_RE ]] && continue
        if [ -n "${CONN[$mac]:-}" ]; then
            bat=$(battery_of "$mac"); [ -n "$bat" ] && bat="  ${bat}%"
            C_ROWS+=("● $name$bat"); C_MAC+=("$mac"); C_NAME+=("$name")
        elif [ -n "${PAIR[$mac]:-}" ]; then
            P_ROWS+=("○ $name"); P_MAC+=("$mac"); P_NAME+=("$name")
        else
            N_ROWS+=("  $name"); N_MAC+=("$mac"); N_NAME+=("$name")
        fi
    done < <(bluetoothctl devices 2>/dev/null)

    ROWS=() KIND=() MAC=() NAME=()
    add() { ROWS+=("$1"); KIND+=("$2"); MAC+=("${3:-}"); NAME+=("${4:-}"); }

    for i in "${!C_ROWS[@]}"; do add "${C_ROWS[i]}" active "${C_MAC[i]}" "${C_NAME[i]}"; done
    for i in "${!P_ROWS[@]}"; do add "${P_ROWS[i]}" paired "${P_MAC[i]}" "${P_NAME[i]}"; done
    for i in "${!N_ROWS[@]}"; do add "${N_ROWS[i]}" new    "${N_MAC[i]}" "${N_NAME[i]}"; done

    # Пусто — один раз ищем синхронно
    if [ "${#ROWS[@]}" -eq 0 ] && [ -z "$scanned" ]; then
        scanned=1
        notify "Поиск устройств..."
        bluetoothctl --timeout 5 scan on >/dev/null 2>&1
        continue
    fi

    add "────────────────────────────────────────────" none
    add "↺ Искать новые устройства (5 сек)" rescan
    [ "${#P_MAC[@]}" -gt 0 ] && add "✕ Забыть сопряжённое устройство…" forget
    add "⏻ Выключить Bluetooth" off

    VISIBLE=${#ROWS[@]}; [ "$VISIBLE" -gt 12 ] && VISIBLE=12
    IDX=$(printf '%s\n' "${ROWS[@]}" |
        fz --index --lines "$VISIBLE" --width 54 --prompt "BLUETOOTH -> ") || exit 0
    [ -z "$IDX" ] && exit 0

    case "${KIND[IDX]}" in
        active) active_menu "${MAC[IDX]}" "${NAME[IDX]}" && exit 0 ;;
        paired) connect_device "${MAC[IDX]}" "${NAME[IDX]}" paired && exit 0 ;;
        new)    connect_device "${MAC[IDX]}" "${NAME[IDX]}" new && exit 0 ;;
        forget) forget_menu P_MAC P_NAME ;;
        rescan)
            notify "Сканирование эфира (5 сек)..."
            bluetoothctl --timeout 5 scan on >/dev/null 2>&1
            ;;
        off)
            bluetoothctl power off >/dev/null 2>&1
            notify "Адаптер выключен"
            exit 0
            ;;
    esac
done
