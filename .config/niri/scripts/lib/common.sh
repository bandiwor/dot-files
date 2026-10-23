# shellcheck shell=bash
# Общие функции для скриптов niri (меню на fuzzel, OSD, скриншоты).
#
# Подключение (в начале скрипта):
#   UI_TITLE=WIFI UI_TAG=wifi-hub
#   . "$(dirname "$(readlink -f "$0")")/lib/common.sh"
#
# UI_TITLE — заголовок уведомлений, UI_TAG — ключ замены: новое уведомление
# с тем же тегом заменяет предыдущее, а не копится стопкой в mako.

UI_TITLE=${UI_TITLE:-NIRI}
UI_TAG=${UI_TAG:-niri}

# fuzzel в режиме dmenu
fz() { fuzzel --dmenu "$@"; }

# notify "текст" [доп. аргументы notify-send, напр. -t 1500 -i файл]
notify() {
    notify-send -h "string:x-canonical-private-synchronous:$UI_TAG" "${@:2}" "$UI_TITLE" "$1"
}

notify_err() {
    notify-send -u critical -h "string:x-canonical-private-synchronous:$UI_TAG" "$UI_TITLE ERROR" "$1"
}

# clamp ЗНАЧЕНИЕ МИН МАКС
clamp() {
    local v=$1
    [ "$v" -lt "$2" ] && v=$2
    [ "$v" -gt "$3" ] && v=$3
    printf '%s' "$v"
}

# bar ПРОЦЕНТ — шкала из 10 делений (без внешних процессов)
bar() {
    local v=${1:-0} f i out=""
    f=$(( (v + 5) / 10 ))
    [ "$f" -gt 10 ] && f=10
    [ "$f" -lt 0 ] && f=0
    for ((i = 0; i < 10; i++)); do
        if ((i < f)); then out+="█"; else out+="░"; fi
    done
    printf '%s' "$out"
}

# confirm ДЕЙСТВИЕ [ПОДСКАЗКА] → 0, если пользователь подтвердил.
# «Нет» стоит первым, поэтому случайный Enter безопасен.
confirm() {
    local ans
    ans=$(printf '%s\n' "Нет, отмена" "Да, $1" |
        fz --index --lines 2 --width 40 --prompt "${2:-Подтвердите}"' -> ') || return 1
    [ "$ans" = "1" ]
}

# Универсальное меню: массивы ROWS (текст), KIND (действие), ARG (аргумент)
menu_reset() { ROWS=(); KIND=(); ARG=(); }
add()        { ROWS+=("$1"); KIND+=("$2"); ARG+=("${3:-}"); }

# show_menu ПРОМПТ ШИРИНА [МАКС_СТРОК] — показывает ROWS, печатает индекс выбора
show_menu() {
    local n=${#ROWS[@]} max=${3:-12}
    [ "$n" -gt "$max" ] && n=$max
    printf '%s\n' "${ROWS[@]}" | fz --index --lines "$n" --width "$2" --prompt "$1"
}
