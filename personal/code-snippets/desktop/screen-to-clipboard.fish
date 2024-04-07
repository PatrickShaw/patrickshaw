#!/usr/bin/env fish
grim - | wl-copy --type image/png

notify-send -t 1000 "Screenshot in clipboard"
