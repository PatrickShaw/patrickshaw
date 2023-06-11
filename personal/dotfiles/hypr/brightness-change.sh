#/bin/bash

MAX="$(brightnessctl -m m)"
CURRENT="$(brightnessctl -m g)"

NEXT="$(frawk "BEGIN { print int($CURRENT $1 $MAX * 0.1 + 0.5) }")"
echo $NEXT

brightnessctl s $NEXT