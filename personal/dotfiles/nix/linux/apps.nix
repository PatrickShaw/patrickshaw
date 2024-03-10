{ pkgs }:
with pkgs; [
  google-chrome
  firefox

  pkgs.gnome.gnome-clocks

  gcc

  gnome-text-editor

  cliphist

  killall

  autotiling-rs

  # CLI based GTK dialog renderer - Similarish in purpose to Wofi
  yad

  adoptopenjdk-bin

  efibootmgr

  libreoffice-fresh

  waybar
  ulauncher

  pamixer

  pavucontrol
  # Prefer qpwgraph to helvum
  qpwgraph

  # Camera app
  gnome.cheese
  # Allows tweaking of camera
  v4l-utils

  ffmpeg-full

  swayidle

  brightnessctl

  frawk

  looking-glass-client

  gnome.nautilus
  gnome.sushi

  # gamescope
  # protontricks
  # proton-caller
  winetricks

  # river

  p7zip
  unzip
  gzip
  gnome.file-roller

  # For lspci
  pciutils
  # For lsusb
  usbutils

  # jack2
  #helvum

  # For lspci
  pciutils
  # For lsusb
  usbutils

  # steam
  # Steam was trying to use this
  xdg-user-dirs
  lutris

  baobab
  cpu-x

  # See: https://nixos.wiki/wiki/Wine
  #wineWowPackages.stable
  wineWowPackages.waylandFull

  spotify
  (signal-desktop.overrideAttrs (old: {
    # See https://github.com/NixOS/nixpkgs/issues/222043#issuecomment-1589411268
    preFixup = old.preFixup + ''
      gappsWrapperArgs+=(
        --add-flags "--enable-features=UseOzonePlatform"
        --add-flags "--ozone-platform=wayland"
      )
    '';
  }))

  celluloid
  # Haven't needed anything other than celluloid
  # haruna

  jetbrains.idea-community

  qbittorrent

  virt-manager
  virtiofsd
  OVMFFull

  vlc

  kitty

  gammastep

  wezterm

  docker
  docker-compose

  phinger-cursors
  papirus-icon-theme

  # I find it doesn't work that well, at least for my setup
  # caprine-bin

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
  
  handlr
  (stdenv.mkDerivation {
    pname = "handler-xdg-open-shim";
    version = "1.0";

    # src = ./.; 

    buildInputs = [ handlr ];

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/bin
      touch $out/bin/xdg-open
      chmod 755 $out/bin/xdg-open
      echo '#!/bin/sh' >> $out/bin/xdg-open
      echo 'handlr open "$@"' >> $out/bin/xdg-open
    '';

    # meta = {
    #   description = "A simple wrapper for handlr using xdg-open";
    #   license = stdenv.lib.licenses.mit;
    # };
  })

  # Has xdg-open in it. I assume a few apps depend on this globally
  # BUT have a look at https://wiki.archlinux.org/title/Default_applications#xdg-open - Apparently this is a different xdg-open implementation
  # Went with handlr instead which provides a way of shimming it
  # xdg-utils

  gptfdisk
  
  # Image viewers
  gnome.eog
  feh

  # Epic game store
  legendary-gl
  heroic

  # Font viewer
  # TODO: Haven't looked at other apps yet
  gnome.gnome-font-viewer


  # See: https://nixos.wiki/wiki/LibreOffice
  # and see: https://wiki.archlinux.org/title/firefox
  hunspell
  hunspellDicts.en_AU-large
  hunspellDicts.en_US

  efibootmgr

  # Zoom was asking for it
  glxinfo

  # Required by eww, it seems
  wmctrl

  wl-clip-persist
]
