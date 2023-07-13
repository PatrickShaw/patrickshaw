#/bin/bash

MAX="$(brightnessctl -m m)"
CURRENT="$(brightnessctl -m g)"

NEXT="$(frawk "BEGIN { print int($CURRENT $1 $MAX * 0.1 + 0.5) }")"

brightnessctl s $NEXT

NEW_CURRENT="$(brightnessctl -m g)"
PERCENT=$(frawk "BEGIN { print int(($NEW_CURRENT / $MAX) * 100 + 0.5)}")
notify-send -r 200000002 -t 1000 --icon display-brightness-symbolic $PERCENT
