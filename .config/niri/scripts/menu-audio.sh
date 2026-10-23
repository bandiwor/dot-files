#!/usr/bin/env bash
# Аудио хаб (Mod+Shift+I): громкость/mute вывода и микрофона, выбор устройств.
# Громкость и mute — wpctl; список и переключение устройств — pactl (pipewire-pulse),
# имена устройств берутся из машинного вывода, а не из рамок `wpctl status`.
# Выбор по индексу (fuzzel --index). После действия возвращаемся в меню, Esc — выход.

fz() { fuzzel --dmenu "$@"; }

notify()     { notify-send -h string:x-canonical-private-synchronous:audio-hub "AUDIO" "$1"; }
notify_err() { notify-send -u critical -h string:x-canonical-private-synchronous:audio-hub "AUDIO ERROR" "$1"; }

SINK=@DEFAULT_AUDIO_SINK@
SRC=@DEFAULT_AUDIO_SOURCE@

bar() {
    local v=${1:-0} f
    f=$(( (v + 5) / 10 )); [ "$f" -gt 10 ] && f=10; [ "$f" -lt 0 ] && f=0
    printf '%s%s' "$(printf '█%.0s' $(seq 1 "$f") 2>/dev/null)" "$(printf '░%.0s' $(seq 1 $((10 - f))) 2>/dev/null)"
}

# vol_of TARGET → "процент muted(0/1)"
vol_of() {
    local raw
    raw=$(wpctl get-volume "$1" 2>/dev/null) || { printf '0 0'; return; }
    awk '{m = ($0 ~ /MUTED/) ? 1 : 0; printf "%d %d", $2 * 100 + 0.5, m}' <<<"$raw"
}

# list_devices sinks|sources → строки "имя<TAB>описание"; мониторы и пустышки скрыты
list_devices() {
    LC_ALL=C pactl list "$1" 2>/dev/null | awk -F'\t' '
        /^\tName: /        { name = substr($2, 7) }
        /^\tDescription: / { desc = substr($2, 14);
                             if (name !~ /\.monitor$/ && name !~ /auto_null/) print name "\t" desc }'
}

pick_level() {
    local -a items=("+5" "-5" "+10" "-10" 100 80 60 40 20 0)
    local idx
    idx=$(printf '%s%%\n' "${items[@]}" | fz --index --lines 10 --width 24 --prompt "$1 ($2%) -> ") || return 1
    [ -z "$idx" ] && return 1
    printf '%s' "${items[idx]}"
}

set_level() {
    local target=$1 label=$2 cur=$3 new
    new=$(pick_level "$label" "$cur") || return 1
    case "$new" in
        +*|-*) wpctl set-volume -l 1.5 "$target" "${new:1}%${new:0:1}" 2>/dev/null ;;
        *)     wpctl set-volume -l 1.0 "$target" "$new%" 2>/dev/null ;;
    esac
}

while true; do
    read -r SV SM <<<"$(vol_of "$SINK")"
    read -r MV MM <<<"$(vol_of "$SRC")"

    mapfile -t SINKS < <(list_devices sinks)
    mapfile -t SOURCES < <(list_devices sources)
    DEF_SINK=$(pactl get-default-sink 2>/dev/null)
    DEF_SRC=$(pactl get-default-source 2>/dev/null)

    sink_desc=""; src_desc=""
    for d in "${SINKS[@]}";   do [ "${d%%$'\t'*}" = "$DEF_SINK" ] && sink_desc=${d#*$'\t'}; done
    for d in "${SOURCES[@]}"; do [ "${d%%$'\t'*}" = "$DEF_SRC" ]  && src_desc=${d#*$'\t'};  done

    ROWS=() KIND=() ARG=()
    add() { ROWS+=("$1"); KIND+=("$2"); ARG+=("${3:-}"); }

    mute_tag() { [ "$1" = "1" ] && printf '  [MUTED]'; }

    add "$(bar "$SV")  $(printf '%3d' "$SV")%  OUT  ${sink_desc:-—}$(mute_tag "$SM")" sink_vol
    add "⏻ $([ "$SM" = 1 ] && echo 'Включить звук' || echo 'Выключить звук')" sink_mute
    add "$(bar "$MV")  $(printf '%3d' "$MV")%  IN   ${src_desc:-—}$(mute_tag "$MM")" src_vol
    add "⏻ $([ "$MM" = 1 ] && echo 'Включить микрофон' || echo 'Выключить микрофон')" src_mute

    add "──────────────── ВЫХОДЫ ─────────────────" none
    for i in "${!SINKS[@]}"; do
        n=${SINKS[i]%%$'\t'*}; d=${SINKS[i]#*$'\t'}
        add "$([ "$n" = "$DEF_SINK" ] && echo '●' || echo '○') $d" set_sink "$n|$d"
    done
    add "──────────────── ВХОДЫ ──────────────────" none
    for i in "${!SOURCES[@]}"; do
        n=${SOURCES[i]%%$'\t'*}; d=${SOURCES[i]#*$'\t'}
        add "$([ "$n" = "$DEF_SRC" ] && echo '●' || echo '○') $d" set_src "$n|$d"
    done

    VISIBLE=${#ROWS[@]}; [ "$VISIBLE" -gt 14 ] && VISIBLE=14
    IDX=$(printf '%s\n' "${ROWS[@]}" |
        fz --index --lines "$VISIBLE" --width 66 --prompt "AUDIO -> ") || exit 0
    [ -z "$IDX" ] && exit 0

    case "${KIND[IDX]}" in
        sink_vol)  set_level "$SINK" "Громкость" "$SV" ;;
        src_vol)   set_level "$SRC" "Микрофон" "$MV" ;;
        sink_mute) wpctl set-mute "$SINK" toggle ;;
        src_mute)  wpctl set-mute "$SRC" toggle ;;
        set_sink)
            if pactl set-default-sink "${ARG[IDX]%%|*}" 2>/dev/null; then
                notify "Вывод: ${ARG[IDX]#*|}"
            else
                notify_err "Не удалось переключить вывод"
            fi
            ;;
        set_src)
            if pactl set-default-source "${ARG[IDX]%%|*}" 2>/dev/null; then
                notify "Вход: ${ARG[IDX]#*|}"
            else
                notify_err "Не удалось переключить вход"
            fi
            ;;
    esac
done
