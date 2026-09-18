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

# Считывание яркости ноутбука
BR_INT=$(brightnessctl -m 2>/dev/null | awk -F, '{print sub(/%/, "", $4) ? $4 : $4}')
BR_INT=${BR_INT:-0}

# Считывание яркости внешнего монитора через DDC/CI
BR_EXT=$(ddcutil getvcp 10 --brief 2>/dev/null | awk '{print $4}')
BR_EXT=${BR_EXT:-0}

BAR_INT=$(make_bar "$BR_INT")
BAR_EXT=$(make_bar "$BR_EXT")

MENU=$(cat << MENU_END
1. Ноутбук:  $BAR_INT
2. HDMI:     $BAR_EXT
────────────────────────────────────────────
3. HDMI:     Выключить питание экрана (Standby)
4. HDMI:     Включить питание экрана (Power ON)
5. Niri:     Обесточить все экраны (DPMS Off)
MENU_END
)

CH=$(echo -e "$MENU" | fuzzel --dmenu --lines 6 --width 50 --prompt="DISPLAY CONTROL -> ")
[ -z "$CH" ] && exit 0

case "$CH" in
    1.*|*Ноутбук*)
        ACT=$(printf "+10%%\n-10%%\n100%%\n75%%\n50%%\n25%%\n10%%" | fuzzel --dmenu --lines 7 --width 20 --prompt="Яркость ноутбука -> ")
        [ -z "$ACT" ] && exit 0
        if [[ "$ACT" =~ ^[+-] ]]; then
            brightnessctl set "$ACT"
        else
            brightnessctl set "${ACT}%"
        fi
        notify-send "DISPLAY" "Яркость ноутбука: $(brightnessctl -m | awk -F, '{print $4}')"
        ;;
    2.*)
        ACT=$(printf "+10\n-10\n100\n75\n50\n25\n10" | fuzzel --dmenu --lines 7 --width 20 --prompt="Яркость HDMI -> ")
        [ -z "$ACT" ] && exit 0
        if [[ "$ACT" =~ ^[+-] ]]; then
            ddcutil setvcp 10 "$ACT" 2>/dev/null
        else
            ddcutil setvcp 10 "$ACT" 2>/dev/null
        fi
        NEW_V=$(ddcutil getvcp 10 --brief 2>/dev/null | awk '{print $4}')
        notify-send "DISPLAY" "Яркость внешнего монитора: ${NEW_V:-$ACT}%"
        ;;
    3.*|*Standby*|*Выключить*)
        # VCP D6 0x04: Power-off / DPM Standby
        ddcutil setvcp D6 4 2>/dev/null
        notify-send "DISPLAY" "Внешний HDMI монитор переведен в Standby"
        ;;
    4.*|*Power*ON*|*Включить*)
        # VCP D6 0x01: DPM Normal On
        ddcutil setvcp D6 1 2>/dev/null
        notify-send "DISPLAY" "Внешний HDMI монитор включен"
        ;;
    5.*|*DPMS*|*Обесточить*)
        niri msg action power-off-monitors
        ;;
esac
