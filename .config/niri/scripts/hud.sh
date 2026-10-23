#!/usr/bin/env bash
# Mod+T — HUD: время, батарея, Wi-Fi, звук. Без резидентного процесса:
# собираем данные, показываем плашкой mako; повторное нажатие закрывает.

TIMEOUT=8000
STATE="${XDG_RUNTIME_DIR:-/tmp}/niri-hud"

if [ -r "$STATE" ]; then
    read -r OLD_ID OLD_TS <"$STATE"
    rm -f "$STATE"
    if [ -n "$OLD_ID" ] && [ $(( $(date +%s) - OLD_TS )) -lt $(( TIMEOUT / 1000 )) ]; then
        makoctl dismiss -n "$OLD_ID" 2>/dev/null
        exit 0
    fi
fi

bar() {
    local v=${1:-0} f
    f=$(( (v + 5) / 10 )); [ "$f" -gt 10 ] && f=10; [ "$f" -lt 0 ] && f=0
    printf '%s%s' "$(printf '█%.0s' $(seq 1 "$f") 2>/dev/null)" "$(printf '░%.0s' $(seq 1 $((10 - f))) 2>/dev/null)"
}

ROWS=()
ROWS+=("$(date '+%H:%M:%S  %a %d.%m.%Y')")

# Батарея
for B in /sys/class/power_supply/BAT*; do
    [ -r "$B/capacity" ] || continue
    CAP=$(<"$B/capacity"); ST=$(<"$B/status")
    case "$ST" in
        Charging) MARK="+" ;;
        Full)     MARK="=" ;;
        *)        MARK="-" ;;
    esac
    ROWS+=("BAT  $(bar "$CAP") $(printf '%3d' "$CAP")% [$MARK]")
    break
done

# Wi-Fi
WIFI=$(nmcli -t --escape no -f IN-USE,SIGNAL,SSID dev wifi list --rescan no 2>/dev/null | grep '^\*:' | head -n 1)
if [ -n "$WIFI" ]; then
    IFS=: read -r _ SIG SSID <<<"$WIFI"
    ROWS+=("WIFI $(bar "$SIG") $(printf '%3d' "$SIG")% $SSID")
else
    ROWS+=("WIFI не подключено")
fi

# Звук
RAW=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
if [ -n "$RAW" ]; then
    VOL=$(awk '{print int($2 * 100)}' <<<"$RAW")
    MUTED=""; grep -q MUTED <<<"$RAW" && MUTED=" [MUTED]"
    ROWS+=("VOL  $(bar "$VOL") $(printf '%3d' "$VOL")%$MUTED")
fi

BODY=$(printf '%s\n' "${ROWS[@]}")
ID=$(notify-send -p -t "$TIMEOUT" -u low "HUD" "$BODY") && echo "$ID $(date +%s)" >"$STATE"
