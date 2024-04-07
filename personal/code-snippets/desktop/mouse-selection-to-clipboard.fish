#!/usr/bin/env fish
grim -g "$(slurp)" - | wl-copy --type image/png

notify-send -t 1000 "Screenshot to clipboard"
