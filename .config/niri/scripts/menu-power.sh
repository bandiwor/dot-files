#!/usr/bin/env bash

BAT_PATH=$(find /sys/class/power_supply -maxdepth 1 -name "BAT*" | head -n 1)

CAP=$(cat "$BAT_PATH/capacity" 2>/dev/null || echo "N/A")
STAT=$(cat "$BAT_PATH/status" 2>/dev/null || echo "N/A")
THRESH=$(cat "$BAT_PATH/charge_control_end_threshold" 2>/dev/null || echo "N/A")
EPP=$(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null || echo "N/A")
BOOST=$(cat /sys/devices/system/cpu/cpufreq/boost 2>/dev/null || echo "0")

[ "$BOOST" = "1" ] && BOOST_TXT="ON" || BOOST_TXT="OFF"

HEADER="BAT: ${CAP}% [${STAT}] │ LIMIT: ${THRESH}% │ EPP: ${EPP} │ BOOST: ${BOOST_TXT}"

MENU=$(cat << 'MENU_END'
1. Profile -> performance (Boost ON)
2. Profile -> balance_performance (Boost ON)
3. Profile -> power (Quiet / Boost OFF)
─────────────────────────────────────────────
4. Charge Limit -> 80% (Desk Mode)
5. Charge Limit -> 100% (Full Travel)
MENU_END
)

CH=$(echo -e "$MENU" | fuzzel --dmenu --lines 6 --width 64 --prompt="$HEADER -> ")

case "$CH" in
    *performance*)
        echo 1 > /sys/devices/system/cpu/cpufreq/boost 2>/dev/null
        for f in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
            echo "performance" > "$f" 2>/dev/null
        done
        notify-send "POWER PROFILE" "Режим: PERFORMANCE (Частота до 4.0+ ГГц)"
        ;;
    *balance_performance*)
        echo 1 > /sys/devices/system/cpu/cpufreq/boost 2>/dev/null
        for f in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
            echo "balance_performance" > "$f" 2>/dev/null
        done
        notify-send "POWER PROFILE" "Режим: BALANCED (Динамический буст)"
        ;;
    *power*)
        echo 0 > /sys/devices/system/cpu/cpufreq/boost 2>/dev/null
        for f in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
            echo "power" > "$f" 2>/dev/null
        done
        notify-send "POWER PROFILE" "Режим: POWER-SAVER (Тихий, частота ≤ 3.17 ГГц)"
        ;;
    *80%*)
        if [ -n "$BAT_PATH" ]; then
            echo 80 > "$BAT_PATH/charge_control_end_threshold"
            notify-send "BATTERY HEALTH" "Порог заряда зафиксирован на 80%"
        fi
        ;;
    *100%*)
        if [ -n "$BAT_PATH" ]; then
            echo 100 > "$BAT_PATH/charge_control_end_threshold"
            notify-send "BATTERY HEALTH" "Порог заряда снят (100%)"
        fi
        ;;
esac
