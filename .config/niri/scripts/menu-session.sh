#!/usr/bin/env bash
# Сессия (Mod+M): блокировка, сон, перезагрузка, выключение, выход из niri.
# Деструктивные действия требуют подтверждения (с числом открытых окон).
# Блокировка запускается отдельно (hyprlock держит процесс до разблокировки,
# поэтому раньше «Suspend» засыпал только ПОСЛЕ ввода пароля).

UI_TITLE=SESSION UI_TAG=session
. "$(dirname "$(readlink -f "$0")")/lib/common.sh"

lock_screen() {
    pgrep -x hyprlock >/dev/null || setsid -f hyprlock >/dev/null 2>&1
}

uptime_h() {
    awk '{ m = int($1 / 60); d = int(m / 1440); h = int((m % 1440) / 60); mm = m % 60;
           if (d > 0) printf "%dд %dч", d, h; else if (h > 0) printf "%dч %02dм", h, mm; else printf "%dм", mm }' /proc/uptime
}

# Подтверждение с числом открытых окон
confirm_session() {
    confirm "$1" "Открыто окон: $(niri msg windows 2>/dev/null | grep -c '^Window ID')"
}

ROWS=("Блокировка" "Сон (suspend)" "Перезагрузка" "Выключение" "Выход из niri")
KIND=(lock suspend reboot poweroff exit)

IDX=$(printf '%s\n' "${ROWS[@]}" |
    fz --index --lines "${#ROWS[@]}" --width 36 --prompt "SESSION · up $(uptime_h) -> ") || exit 0
[ -z "$IDX" ] && exit 0

case "${KIND[IDX]}" in
    lock)    lock_screen ;;
    suspend) lock_screen; sleep 0.4; systemctl suspend ;;
    reboot)  confirm_session "перезагрузить"  && systemctl reboot ;;
    poweroff) confirm_session "выключить"     && systemctl poweroff ;;
    exit)    confirm_session "выйти из niri"  && niri msg action quit --skip-confirmation ;;
esac
