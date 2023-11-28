#!/usr/bin/env bash
yad --list --title="Stop recording?" --button=Stop:0 --undecorated --no-focus --on-top --sticky

exit_status=$?

if [ $exit_status -eq 0 ]; then
    # The Stop button was pressed
    killall wf-recorder
fi
