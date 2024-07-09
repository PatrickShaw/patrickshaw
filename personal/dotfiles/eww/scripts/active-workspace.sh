#!/usr/bin/env bash

activeWorkspace() {
  # https://wiki.hyprland.org/Configuring/Expanding-functionality/
  hyprctl monitors -j | jaq .[0].activeWorkspace.id  
}

activeWorkspace
socat -u UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - | while read -r line; do
	activeWorkspace
done