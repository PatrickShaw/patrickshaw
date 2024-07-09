{ pkgs }:
with pkgs; [
  # google-chrome

  pkgs.gnome.gnome-clocks

  gcc

  gnome-text-editor

  cliphist

  killall

  autotiling-rs

  # CLI based GTK dialog renderer - Similarish in purpose to Wofi
  yad


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
  # v4l-utils

  # If you ever need specific dependencies, you can add them manually. Smaller than resorting to ffmpeg-full
  ffmpeg

  # This is great for figuring out which apps take up a lot of space
  nix-tree

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

  # jack2
  #helvum

  # For lspci
  pciutils
  # For lsusb
  usbutils

  # steam
  # Steam was trying to use this
  xdg-user-dirs
  #lutris

  baobab
  cpu-x

  # See: https://nixos.wiki/wiki/Wine
  #wineWowPackages.stable
  wineWowPackages.waylandFull
  samba # Fixes ntlm_auth wine errors. See https://github.com/NixOS/nixpkgs/issues/126801#issuecomment-930431829

  spotify
  #(signal-desktop.overrideAttrs (old: {
    # See https://github.com/NixOS/nixpkgs/issues/222043#issuecomment-1589411268
  #  preFixup = old.preFixup + ''
  #    gappsWrapperArgs+=(
  #      --add-flags "--enable-features=UseOzonePlatform"
  #      --add-flags "--ozone-platform=wayland"
  #    )
  #  '';
  #}))

  celluloid
  # Haven't needed anything other than celluloid and mpv
  # haruna

  # Haven't used this in a while and it's very big so commented out for now
  # jetbrains.idea-community

  qbittorrent

  virt-manager
  virtiofsd
  OVMFFull

  # There's a lot of much better alternatives, so removed this classic
  # vlc

  kitty

  gammastep

  wezterm

  #docker
  #docker-compose

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
  # legendary-gl
  # heroic

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


  # Can be used to configure mice who's software isn't available on Linux
  libratbag
  # And this is the UI for it
  piper

  # Don't remember why exactly I added these but I imagine they're for getting XDG-open to work properly
  shared-mime-info
  desktop-file-utils
]
