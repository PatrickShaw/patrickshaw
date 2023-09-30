#!/usr/bin/env bash
# Seems to be a bug with immediately running it but also - Probably don't need this consuming precious bootup time imemdiately
sleep 0.5

PREV_ID=""
activeWorkspace() {
  # https://wiki.hyprland.org/Configuring/Expanding-functionality/
  ID=$(hyprctl monitors -j | jaq .[0].activeWorkspace.id)
  if [ "$ID" == "$PREV_ID" ]; then
    return 0
  fi

  declare -A idToImg
  
  echo switch

  idToImg["1"]="wyqdvp.jpg"
  idToImg["2"]="96kq3x.png"
  idToImg["3"]="k9p8l6.jpg"
  idToImg["4"]="e77g8k.jpg"
  idToImg["5"]="rd3xvm.jpg"
  idToImg["6"]="39ode6.png"
  idToImg["7"]="4dz9ln.jpg"
  idToImg["8"]="4yrzml.jpg"
  idToImg["9"]="39ode6.png"
  idToImg["0"]="eyw8yr.jpg"
  
  IMG_FILENAME=$(echo ${idToImg["$ID"]})
  PREV_ID=$ID
  swww img --transition-type=simple --transition-fps=60 --transition-step=48 $HOME/wallpapers/wallhaven/$IMG_FILENAME
}

activeWorkspace
socat -u UNIX-CONNECT:/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - | while read -r line; do
	activeWorkspace
done