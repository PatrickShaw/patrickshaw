#/bin/bash

playerctl play-pause

STATUS=$(playerctl status)

if [ $STATUS == "Playing" ]; then
  notify-send -r 1000000000 -t 1000 --icon media-playback-start --urgency critical --category sound --transient Playing
else 
  notify-send -r 1000000000 -t 1000 --icon media-playback-pause --urgency critical --category sound --transient Paused
fi