#!/usr/bin/env fish
grim -g (swaymsg -t get_tree | jq -j '.. | select(.type?) | select(.focused).rect | "\(.x),\(.y) \(.width)x\(.height)"') - | wl-copy --type image/png