#!/usr/bin/env bash
DEFAULT_SINK=$(pactl info | grep "Default Sink" | cut -d " " -f3)
IS_MUTE=$(pactl get-sink-mute $DEFAULT_SINK | cut -d " " -f2)
if [ $IS_MUTE == "yes" ]; then
  echo "mute"
else
  VOLUME=$(pamixer --get-volume)
  LEVEL=$(echo $VOLUME | frawk '{ if ($1 <= 0) print "zero"; else if ($1 <= 33) print "low"; else if ($1 <= 66) print "medium"; else print "high";  }')
  echo $LEVEL
fi
