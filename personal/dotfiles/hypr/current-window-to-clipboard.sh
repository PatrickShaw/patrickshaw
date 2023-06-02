#!/bin/sh
grim -g "$(hyprctl activewindow -j | jaq  '.at[0], ",", .at[1], " ", .size[0], "x", .size[1]' --raw-output -j -c)" - | wl-copy