#!/usr/bin/env bash
# Mod+T — плашка часов/батареи (waybar): первое нажатие запускает, второе закрывает.
# Пока плашка скрыта, процесса нет — ноль потребления.
if pkill -x waybar; then
    exit 0
fi
exec waybar
