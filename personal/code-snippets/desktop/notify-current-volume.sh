#!/usr/bin/env sh

VOLUME=$(pamixer --get-volume)
notify-send -r 2139132199 -t 1000 --icon audio-volume-high 10%