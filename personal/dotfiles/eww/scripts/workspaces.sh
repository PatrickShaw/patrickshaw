#!/bin/sh

workspaces() {
  # https://wiki.hyprland.org/Configuring/Expanding-functionality/
  hyprctl workspaces -j | jaq -c 'sort_by(.id)'
  #notify-send -r 200000002 -t 1000 --icon audio-volume-high-symbolic hmmm
}

workspaces
socat -u UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - | while read -r line; do
	workspaces
done