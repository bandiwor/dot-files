#!/usr/bin/env bash

make_bar() {
    local val=${1:-0}
    local total=10
    local filled=$(( (val + 5) / 10 ))
    [ "$filled" -gt 10 ] && filled=10
    [ "$filled" -lt 0 ] && filled=0
    local empty=$(( total - filled ))
    printf "[%s%s] %3d%%" "$(printf '█%.0s' $(seq 1 $filled 2>/dev/null))" "$(printf '░%.0s' $(seq 1 $empty 2>/dev/null))" "$val"
}

# Считывание текущего статуса громкости и Mute
VOL_RAW=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
VOL=$(echo "$VOL_RAW" | awk '{print int($2 * 100)}')
VOL=${VOL:-0}
MUTED=$(echo "$VOL_RAW" | grep -q "MUTED" && echo "[MUTED]" || echo "[ON]")

MIC_RAW=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null)
MIC_MUTED=$(echo "$MIC_RAW" | grep -q "MUTED" && echo "[MUTED]" || echo "[ON]")

BAR_VOL=$(make_bar "$VOL")

# Сборка списка выходов звука (Sinks)
SINKS_LIST=$(wpctl status 2>/dev/null | awk '
/Audio/,/Video/ {
    if ($0 ~ /Sinks:/) { in_sinks=1; next }
    if ($0 ~ /Sources:/) { in_sinks=0; next }
    if (in_sinks && $0 ~ /^[│ ]*[ *]*[0-9]+\./) {
        line = $0
        sub(/^[│ ]*/, "", line)
        is_active = (line ~ /^\*/) ? 1 : 0
        sub(/^\*?[ ]*/, "", line)
        id = line
        sub(/\..*/, "", id)
        name = line
        sub(/^[0-9]+\.[ ]*/, "", name)
        sub(/\[vol:.*$/, "", name)
        gsub(/[ \t]+$/, "", name)

        if (name ~ /Dummy/ || name == "") next

        mark = is_active ? "[x]" : "[ ]"
        printf "%s %-4s │ %s\n", mark, id, name
    }
}')

MENU=$(cat << MENU_END
1. Громкость: $BAR_VOL $MUTED
2. Вывод звука: Переключить устройство (Sink)
3. Звук:      Mute / Unmute вывода
4. Микрофон:  Mute / Unmute входа $MIC_MUTED
MENU_END
)

CH=$(echo -e "$MENU" | fuzzel --dmenu --lines 5 --width 54 --prompt="AUDIO CONTROL -> ")
[ -z "$CH" ] && exit 0

case "$CH" in
    1*|*Громкость*)
        ACT=$(printf "+5%%\n-5%%\n+10%%\n-10%%\n100%%\n80%%\n50%%\n25%%\n0%%" | fuzzel --dmenu --lines 9 --width 20 --prompt="Громкость -> ")
        [ -z "$ACT" ] && exit 0
        if [[ "$ACT" =~ ^[+-] ]]; then
            wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ "$ACT"
        else
            wpctl set-volume @DEFAULT_AUDIO_SINK@ "$ACT"
        fi
        CURR_V=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}')
        notify-send "AUDIO" "Громкость: ${CURR_V}%"
        ;;
    2*|*Вывод*)
        SINK_CH=$(echo -e "$SINKS_LIST" | fuzzel --dmenu --lines 6 --width 64 --prompt="ВЫБОР ВЫХОДА ЗВУКА -> ")
        [ -z "$SINK_CH" ] && exit 0
        TARGET_ID=$(echo "$SINK_CH" | awk '{print $2}')
        if [ -n "$TARGET_ID" ]; then
            wpctl set-default "$TARGET_ID"
            SINK_NAME=$(echo "$SINK_CH" | cut -d'│' -f2 | xargs)
            notify-send "AUDIO DEVICE" "Вывод звука переключен на:\n$SINK_NAME"
        fi
        ;;
    3*|*вывода*)
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        NEW_ST=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q "MUTED" && echo "Выключен [MUTE]" || echo "Включен [UNMUTE]")
        notify-send "AUDIO" "Звук: $NEW_ST"
        ;;
    4*|*Микрофон*)
        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
        NEW_MIC=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q "MUTED" && echo "Заглушен [MUTE]" || echo "Активен [UNMUTE]")
        notify-send "MICROPHONE" "Микрофон: $NEW_MIC"
        ;;
esac
