#!/usr/bin/env bash
# Скриншоты: grim + slurp (+ niri для окна).
#   screenshot.sh area      — выбор области (Print)
#   screenshot.sh all       — все экраны одним кадром (Shift+Print, по умолчанию)
#   screenshot.sh output    — текущий монитор
#   screenshot.sh window    — активное окно (штатное действие niri)
#   screenshot.sh menu      — меню режимов (Mod+Print), в т.ч. с задержкой
# Снимок пишется в ~/Pictures и сразу копируется в буфер (один проход grim, без перечитывания файла).

DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}"
FILE="$DIR/$(date +'%Y-%m-%d-%H%M%S')_shot.png"

UI_TITLE=SCREENSHOT UI_TAG=screenshot
. "$(dirname "$(readlink -f "$0")")/lib/common.sh"

focused_output() {
    niri msg focused-output 2>/dev/null | sed -n 's/^Output .*(\(.*\))$/\1/p' | head -n 1
}

# capture [grim-аргументы…] — снимок → файл + буфер
capture() {
    mkdir -p "$DIR"
    if ! grim "$@" - | tee "$FILE" | wl-copy -t image/png; then
        notify_err "grim не смог сделать снимок"
        return 1
    fi
    if [ -s "$FILE" ]; then
        notify "Сохранено: ${FILE/#$HOME/\~}" -i "$FILE"
    else
        rm -f "$FILE"
        notify_err "Пустой снимок"
        return 1
    fi
}

select_area() {
    # Монохромная рамка в стиле остального интерфейса
    slurp -b 0a0a0a99 -c f2f2f2ff -s 00000000 -w 1 || return 1
}

delay() { # delay СЕК — с обратным отсчётом в уведомлении
    local s=$1
    while [ "$s" -gt 0 ]; do
        notify "Снимок через ${s} с…" -t 1100
        sleep 1
        s=$((s - 1))
    done
}

run() {
    case "$1" in
        area)
            local geom; geom=$(select_area) || exit 0
            capture -g "$geom"
            ;;
        output)
            local out; out=$(focused_output)
            if [ -n "$out" ]; then capture -o "$out"; else capture; fi
            ;;
        window)
            # Штатное действие niri: окно уходит в буфер обмена
            niri msg action screenshot-window && notify "Окно скопировано в буфер"
            ;;
        all|"") capture ;;
    esac
}

if [ "${1:-}" = "menu" ]; then
    ROWS=("Область" "Окно" "Текущий экран" "Все экраны" "Область — через 3 с" "Текущий экран — через 5 с")
    MODE=(area window output all area output)
    WAIT=(0 0 0 0 3 5)
    IDX=$(printf '%s\n' "${ROWS[@]}" | fz --index --lines "${#ROWS[@]}" --width 36 --prompt "SCREENSHOT -> ") || exit 0
    [ -z "$IDX" ] && exit 0
    # Область выбираем сразу, отсчёт — после выбора, пока готовишь сцену
    if [ "${WAIT[IDX]}" -gt 0 ] && [ "${MODE[IDX]}" = "area" ]; then
        GEOM=$(select_area) || exit 0
        delay "${WAIT[IDX]}"
        capture -g "$GEOM"
        exit
    fi
    [ "${WAIT[IDX]}" -gt 0 ] && delay "${WAIT[IDX]}"
    run "${MODE[IDX]}"
else
    run "${1:-all}"
fi
