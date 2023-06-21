{ pkgs }:
with pkgs; [
  google-chrome
  firefox

  pkgs.gnome.gnome-clocks

  gcc

  killall

  autotiling-rs

  waybar
  ulauncher

  pavucontrol
  # Prefer qpwgraph: helvum
  qpwgraph

  # Camera app
  gnome.cheese
  # Allows tweaking of camera
  v4l-utils

  brightnessctl

  frawk

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

  virt-manager
  virtiofsd
  OVMFFull

  vlc

  kitty

  wezterm

  docker
  docker-compose

  phinger-cursors
  papirus-icon-theme
  
  # Some great programs mentioned over at https://github.com/ibraheemdev/modern-unix
  tldr
  cheat

  bottom
  glances
  
  hyperfine
  
  gping
  
  procs

  curlie
  xh

  dogdns

  lsd

  du-dust

  caprine-bin
  
  duf

  broot

  fd

  ripgrep

  choose

  mcfly

  orchis-theme

  obsidian

  playerctl

  cpu-x

  # See "External monitors" in https://wiki.archlinux.org/title/backlight
  ddcutil
  # UI
  ddcui


  # See: https://nixos.wiki/wiki/GNOME and the "Known Issues" section of "https://nixos.wiki/wiki/Lutris"
  gnome.adwaita-icon-theme
  # Added assuming it might cause the same problems as above ^
  hicolor-icon-theme

  newsflash

  # For managing workspaces
  jaq
  socat
  
  handlr

  # Has xdg-open in it. I assume a few apps depend on this globally
  xdg-utils
]
