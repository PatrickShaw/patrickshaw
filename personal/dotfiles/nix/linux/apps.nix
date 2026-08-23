# System-wide Linux packages.
#
# Deliberately small: hardware/firmware tooling, diagnostics that are useful as
# root, virtualisation helpers, and the XDG/mime databases that system services
# and every desktop app rely on.
#
# Desktop applications live in the user profile instead - see
# shared/home-manager/modules/linux-desktop.nix.
{ pkgs }:
with pkgs; [
  # Boot/disk administration
  efibootmgr
  gptfdisk

  # Diagnostics that are routinely needed as root
  # pciutils for lspci, usbutils for lsusb
  pciutils
  usbutils
  lsof
  killall
  mesa-demos

  # Fixes ntlm_auth wine errors.
  # See https://github.com/NixOS/nixpkgs/issues/126801#issuecomment-930431829
  samba

  # libvirt/QEMU need these on the system side
  virtiofsd
  OVMFFull

  # Steam was trying to use this
  xdg-user-dirs

  # Icon themes are resolved out of XDG_DATA_DIRS, so they stay system-wide.
  # See: https://nixos.wiki/wiki/GNOME and the "Known Issues" section of "https://nixos.wiki/wiki/Lutris"
  adwaita-icon-theme
  # Added assuming it might cause the same problems as above ^
  hicolor-icon-theme

  # Don't remember why exactly I added these but I imagine they're for getting XDG-open to work properly
  shared-mime-info
  desktop-file-utils

  # gpg-agent resolves its pinentry program from the system profile
  pinentry-all
]
