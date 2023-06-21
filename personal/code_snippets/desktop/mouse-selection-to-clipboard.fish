#!/usr/bin/env fish
grim -g (slurp) - | wl-copy

notify-send -t 1000 "Screenshot to clipboard"
