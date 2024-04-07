#!/bin/sh
DIMENSIONS=$(hyprctl activewindow -j | jaq  '.at[0], ",", .at[1], " ", .size[0], "x", .size[1]' --raw-output -j -c)
grim - "$DIMENSIONS" - | wl-copy --type image/png
TITLE=$(hyprctl activewindow -j | jaq  '.title' --raw-output -j -c)

notify-send -t 3000 "Screenshot caputed for \"$TITLE\""
