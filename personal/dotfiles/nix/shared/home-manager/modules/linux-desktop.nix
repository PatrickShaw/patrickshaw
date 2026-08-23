# Linux desktop applications and user session services.
#
# Previously `environment.systemPackages` in linux/apps.nix. Hardware,
# firmware and mime-database tooling stays system-wide (see that file); this
# is the part that is just "the apps I use".
{ lib, pkgs, ... }:
let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
in {
  # Importing this on macOS would otherwise fail deep inside some package with
  # "is not supported on aarch64-darwin" and no hint as to why it was pulled
  # in. Everything below is behind mkIf so it stays unevaluated on the wrong
  # platform and this assertion is what actually gets reported.
  assertions = [
    {
      assertion = isLinux;
      message = "homeModules.linux-desktop is Linux only, but was imported on ${pkgs.stdenv.hostPlatform.system}.";
    }
  ];

  xdg.userDirs = lib.mkIf isLinux {
    enable = true;
    createDirectories = true;

    # Prefer xdg-user-dir over exporting legacy directory variables globally.
    setSessionVariables = false;
  };

  # Was programs.nm-applet.enable at system level, which starts the applet for
  # every graphical session on the box. As a user service it belongs to me.
  services.network-manager-applet.enable = lib.mkIf isLinux true;

  # Required in order to show authentication prompts (even works with
  # fingerprints). This was already a *user* unit, it was just declared
  # system-wide via systemd.user, which starts it for every account.
  # See: https://nixos.wiki/wiki/Polkit
  # See: https://wiki.hyprland.org/Useful-Utilities/Must-have/#authentication-agent
  systemd.user.services.polkit-gnome-authentication-agent-1 = lib.mkIf isLinux {
    Unit = {
      Description = "polkit-gnome-authentication-agent-1";
      Wants = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  home.packages = lib.mkIf isLinux (with pkgs; [
    # google-chrome

    gnome-clocks

    gcc

    gnome-text-editor

    cliphist

    autotiling-rs

    # CLI based GTK dialog renderer - Similarish in purpose to Wofi
    yad

    libreoffice-fresh

    waybar
    ulauncher

    pamixer

    pavucontrol
    # Prefer qpwgraph to helvum
    qpwgraph

    # Camera app
    cheese
    # Allows tweaking of camera
    # v4l-utils

    # If you ever need specific dependencies, you can add them manually. Smaller than resorting to ffmpeg-full
    ffmpeg

    # This is great for figuring out which apps take up a lot of space
    nix-tree

    swayidle

    brightnessctl

    # Broken ATM:
    #frawk

    looking-glass-client

    nautilus
    sushi

    # gamescope
    # protontricks
    # proton-caller
    winetricks

    # river

    p7zip
    unzip
    gzip
    file-roller

    # jack2
    #helvum

    # steam
    #lutris

    baobab
    cpu-x

    # See: https://nixos.wiki/wiki/Wine
    #wineWowPackages.stable
    wineWow64Packages.waylandFull

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

    # There's a lot of much better alternatives, so removed this classic
    # vlc

    kitty

    gammastep

    # Replaces wezterm. On Linux nixpkgs builds ghostty from source
    ghostty

    #docker
    #docker-compose

    phinger-cursors
    papirus-icon-theme

    # I find it doesn't work that well, at least for my setup
    # caprine-bin

    orchis-theme

    obsidian

    playerctl

    # ddcutil itself stays in the system profile - it needs root for i2c and
    # is granted NOPASSWD sudo by absolute /run/current-system/sw/bin path.
    # See "External monitors" in https://wiki.archlinux.org/title/backlight
    ddcui

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

    # Image viewers
    eog
    feh

    # Epic game store
    # legendary-gl
    # heroic

    # Font viewer
    # TODO: Haven't looked at other apps yet
    gnome-font-viewer

    # See: https://nixos.wiki/wiki/LibreOffice
    # and see: https://wiki.archlinux.org/title/firefox
    hunspell
    hunspellDicts.en_AU-large
    hunspellDicts.en_US

    # Required by eww, it seems
    wmctrl

    wl-clip-persist

    # Can be used to configure mice who's software isn't available on Linux
    libratbag
    # And this is the UI for it
    piper

    # Layer on top of Docker/Podman/OCI to run Linux distros in containers
    distrobox
  ]);
}
