#!/usr/bin/env bash
CURRENT_DIR=$(dirname $0)
$CURRENT_DIR/current-audio-level.sh
pactl subscribe |
    while IFS= read -r event; do
        if echo "$event" | grep -q "sink"; then
          $CURRENT_DIR/current-audio-level.sh
        fi
    done