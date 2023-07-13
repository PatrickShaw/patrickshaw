#/bin/bash

DEFAULT_SINK=$(pactl info | grep "Default Sink" | cut -d " " -f3)
pactl set-sink-mute $DEFAULT_SINK toggle

NEW_VALUE=$(pactl get-sink-mute $DEFAULT_SINK | cut -d " " -f2)
if [ $NEW_VALUE == "yes" ]; then
  notify-send -r 1324923424 -t 1000 --icon audio-volume-muted-symbolic Muted --urgency critical --category sound --transient
else
  VOLUME=$(pamixer --get-volume)
  notify-send -r 1324923424 -t 1000 --icon audio-volume-high-symbolic $VOLUME --urgency critical --category sound --transient
fi