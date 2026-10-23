#!/usr/bin/env bash
# История буфера (Mod+Y — выбор, Mod+Shift+Y — очистка): cliphist + fuzzel.
# Строки показываются без служебных id, картинки — с размером; выбор по индексу.
# Внизу списка: удаление одной записи и очистка истории (с подтверждением).

fz() { fuzzel --dmenu "$@"; }

notify() { notify-send -t 1500 -h string:x-canonical-private-synchronous:clipboard "CLIPBOARD" "$1"; }

MAX=300
BIN_RE='^\[\[ binary data ([0-9.]+ [KMG]?i?B) ([a-z]+) ([0-9]+)x([0-9]+) \]\]$'

confirm_wipe() {
    local ans
    ans=$(printf '%s\n' "Нет, отмена" "Да, очистить всю историю" |
        fz --index --lines 2 --width 40 --prompt "Очистка буфера -> ") || return 1
    [ "$ans" = "1" ]
}

wipe() {
    if confirm_wipe; then
        cliphist wipe
        notify "История очищена"
    fi
}

# Читает историю в массивы RAW (строка cliphist) и SHOW (красивая строка)
load() {
    RAW=() SHOW=()
    local line body
    while IFS= read -r line; do
        body=${line#*$'\t'}
        RAW+=("$line")
        if [[ "$body" =~ $BIN_RE ]]; then
            SHOW+=("▣ ${BASH_REMATCH[2]^^}  ${BASH_REMATCH[3]}×${BASH_REMATCH[4]}  ·  ${BASH_REMATCH[1]}")
        else
            body=$(tr -s '[:space:]' ' ' <<<"$body")
            body=${body# }
            [ "${#body}" -gt 90 ] && body="${body:0:89}…"
            SHOW+=("$body")
        fi
    done < <(cliphist list 2>/dev/null | head -n "$MAX")
}

copy_entry() {
    local line=$1 body mime
    body=${line#*$'\t'}
    if [[ "$body" =~ $BIN_RE ]]; then
        case "${BASH_REMATCH[2]}" in
            jpg|jpeg) mime=image/jpeg ;;
            webp)     mime=image/webp ;;
            *)        mime=image/png ;;
        esac
        printf '%s\n' "$line" | cliphist decode | wl-copy --type "$mime"
        notify "Изображение скопировано"
    else
        printf '%s\n' "$line" | cliphist decode | wl-copy
        notify "Текст скопирован"
    fi
}

pick() { # pick ПРОМПТ → индекс в SHOW
    local lines=${#SHOW_ALL[@]}; [ "$lines" -gt 12 ] && lines=12
    printf '%s\n' "${SHOW_ALL[@]}" | fz --index --lines "$lines" --width 70 --prompt "$1"
}

main() {
    load
    if [ "${#RAW[@]}" -eq 0 ]; then
        notify "История пуста"
        exit 0
    fi

    SHOW_ALL=("${SHOW[@]}" "────────────────────────────────────────" "✕ Удалить запись…" "✕ Очистить историю")
    local n=${#RAW[@]} idx
    idx=$(pick "CLIPBOARD (${n}) -> ") || exit 0
    [ -z "$idx" ] && exit 0

    if [ "$idx" -lt "$n" ]; then
        copy_entry "${RAW[idx]}"
        return
    fi
    case $(( idx - n )) in
        1)  # Удалить запись
            SHOW_ALL=("${SHOW[@]}")
            idx=$(pick "УДАЛИТЬ ЗАПИСЬ -> ") || exit 0
            [ -z "$idx" ] && exit 0
            printf '%s\n' "${RAW[idx]}" | cliphist delete && notify "Запись удалена"
            ;;
        2) wipe ;;
    esac
}

case "${1:-menu}" in
    menu) main ;;
    wipe) wipe ;;
esac
