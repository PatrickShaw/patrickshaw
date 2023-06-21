#!/usr/bin/env sh

#DEFAULT_SINK=$(pactl info | grep "Default Sink" | cut -d " " -f3)
#pactl set-sink-volume $DEFAULT_SINK $1
#pactl set-sink-mute $DEFAULT_SINK false
pamixer $1 $2

VOLUME=$(pamixer --get-volume)
notify-send -r 1324923423 -t 1000 --icon audio-volume-high-symbolic --urgency critical --category sound --transient $VOLUME
