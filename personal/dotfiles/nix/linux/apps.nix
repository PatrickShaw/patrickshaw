{ pkgs }:
with pkgs; [
  google-chrome
  firefox

  gcc

  killall

  autotiling-rs

  waybar
  ulauncher

  pavucontrol
  helvum

  looking-glass-client

  gnome.nautilus
  gnome.sushi

  gamescope
  protontricks
  proton-caller
  winetricks
  
  river

  p7zip
  unzip
  gzip
  
  # For lspci
  pciutils
  # For lsusb
  usbutils
  
  jack2
  #helvum

  # For lspci
  pciutils
  # For lsusb
  usbutils

  jack2
  #helvum

  steam
  # Steam was trying to use this
  xdg-user-dirs
  lutris

  baobab
  cpu-x

  # See: https://nixos.wiki/wiki/Wine
  #wineWowPackages.stable
  wineWowPackages.waylandFull

  spotify
  signal-desktop

  celluloid
  haruna

  qbittorrent

  _1password-gui

  virt-manager
  virtiofsd
  OVMFFull

  vlc

  kitty

  wezterm
  vlc

  docker
  docker-compose

  phinger-cursors

  obsidian

  cpu-x

  # See "External monitors" in https://wiki.archlinux.org/title/backlight
  ddcutil
]
