#!/usr/bin/env bash
# Сессия (Mod+M): блокировка, сон, перезагрузка, выключение, выход из niri.
# Деструктивные действия требуют подтверждения (с числом открытых окон).
# Блокировка запускается отдельно (hyprlock держит процесс до разблокировки,
# поэтому раньше «Suspend» засыпал только ПОСЛЕ ввода пароля).

fz() { fuzzel --dmenu "$@"; }

lock_screen() {
    pgrep -x hyprlock >/dev/null || setsid -f hyprlock >/dev/null 2>&1
}

uptime_h() {
    awk '{ m = int($1 / 60); d = int(m / 1440); h = int((m % 1440) / 60); mm = m % 60;
           if (d > 0) printf "%dд %dч", d, h; else if (h > 0) printf "%dч %02dм", h, mm; else printf "%dм", mm }' /proc/uptime
}

# confirm "Действие" → 0 если подтверждено; «Нет» стоит первым — случайный Enter безопасен
confirm() {
    local wins ans
    wins=$(niri msg windows 2>/dev/null | grep -c '^Window ID')
    ans=$(printf '%s\n' "Нет, отмена" "Да, $1" |
        fz --index --lines 2 --width 40 --prompt "Открыто окон: ${wins:-?} -> ") || return 1
    [ "$ans" = "1" ]
}

ROWS=("Блокировка" "Сон (suspend)" "Перезагрузка" "Выключение" "Выход из niri")
KIND=(lock suspend reboot poweroff exit)

IDX=$(printf '%s\n' "${ROWS[@]}" |
    fz --index --lines "${#ROWS[@]}" --width 36 --prompt "SESSION · up $(uptime_h) -> ") || exit 0
[ -z "$IDX" ] && exit 0

case "${KIND[IDX]}" in
    lock)    lock_screen ;;
    suspend) lock_screen; sleep 0.4; systemctl suspend ;;
    reboot)  confirm "перезагрузить"  && systemctl reboot ;;
    poweroff) confirm "выключить"     && systemctl poweroff ;;
    exit)    confirm "выйти из niri"  && niri msg action quit --skip-confirmation ;;
esac
