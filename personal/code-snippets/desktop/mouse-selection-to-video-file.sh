#!/usr/bin/env bash
VIDEO_FILE=$(date +'recording_%Y-%m-%d-%H%M%S.mp4')

DIRNAME=$(dirname "$0")
$DIRNAME/stop-wf-recorder-dialog.sh &

timeout 60 notify-send -t 1000 'Started recording...' && wf-recorder -g "$(slurp)" -F fps=60 -f ~/Screencasts/$VIDEO_FILE 
notify-send -t 3000 "Recording written to $VIDEO_FILE"
