#/bin/bash

DEFAULT_SINK=$(pactl info | grep "Default Sink" | cut -d " " -f3)
pactl set-sink-mute $DEFAULT_SINK toggle