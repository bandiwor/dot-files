# niri: меню и скрипты

Все меню — fuzzel (dmenu), выбор по индексу, общий код в `scripts/lib/common.sh`.
Уведомления — mako; повторное уведомление того же меню заменяет предыдущее.

| Клавиши | Скрипт | Что делает |
|---|---|---|
| `Mod+R` | fuzzel | Запуск приложений |
| `Mod+N` | `menu-wifi.sh` | Wi-Fi (NetworkManager) |
| `Mod+Shift+N` | `menu-bluetooth.sh` | Bluetooth (bluez) |
| `Mod+I` | `menu-display.sh` | Яркость ноутбука / HDMI (DDC/CI), питание экранов |
| `Mod+Shift+I` | `menu-audio.sh` | Громкость, mute, выбор устройств |
| `Mod+P` | `menu-power.sh` | Профиль питания, Turbo Boost, лимит заряда |
| `Mod+M` | `menu-session.sh` | Блокировка, сон, перезагрузка, выключение, выход |
| `Mod+T` | `hud.sh` | Плашка часов/батареи (waybar): вкл/выкл |
| `Mod+Y` / `Mod+Shift+Y` | `clipboard.sh` | История буфера / очистка |
| `Print` / `Shift+Print` | `screenshot.sh` | Область / все экраны |
| `Mod+Print` / `Alt+Print` | `screenshot.sh` | Меню режимов / активное окно |
| `XF86Audio*`, `XF86MonBrightness*` | `osd.sh`, `media.sh` | OSD громкости, яркости, медиа |

## Зависимости

`niri fuzzel mako waybar hyprlock hypridle networkmanager bluez-utils wireplumber
pipewire-pulse libpulse power-profiles-daemon upower brightnessctl ddcutil grim slurp
wl-clipboard cliphist playerctl libnotify ttf-jetbrains-mono-nerd`

Запись в `/sys` (Turbo Boost, лимит заряда) идёт напрямую, затем через `sudo -n` и `pkexec`;
для `pkexec` нужен запущенный polkit-агент.
