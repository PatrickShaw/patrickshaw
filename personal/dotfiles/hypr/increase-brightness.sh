#/bin/bash

MAX="$(brightnessctl -m m)"
CURRENT="$(brightnessctl -m g)"

NEXT="$(echo $CURRENT $MAX | frawk '{ printf int($1 + $2 * 0.1) }')"

brightnessctl s $NEXT