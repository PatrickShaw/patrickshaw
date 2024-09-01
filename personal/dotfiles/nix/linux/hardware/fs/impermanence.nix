{ boot, persist, nixStore }:
let
  persist-directories = directories: builtins.foldl' (fileSystems: directory: (fileSystems // {
    "${directory}" = {
      device = "/persist${directory}";
      fsType = "none";
      options = ["bind"];
    };
  })) {} directories;
in
{
  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=8G" "mode=755" ];
      neededForBoot = true;
    };

    "/boot" = {
      device = boot.device;
      fsType = "vfat";
      options = [ "defaults" "discard"
        # See https://discourse.nixos.org/t/security-warning-when-installing-nixos-23-11/37636
        "umask=0077" 
      ];
      
    };

    "/persist" = {
      device = persist.device;
      fsType = "btrfs";
      options = [
        "defaults"
        "subvol=persist-root"
        "rw"
        "relatime"
        "discard=async"
        "compress=zstd:1"
        "ssd"
        "space_cache=v2"
      ];
      neededForBoot = true;
    };

    "/nix" = {
      device = "/persist/nix";
      fsType = "none";
      options = [ "bind" ];
      neededForBoot = true;
    };

    "/persist/nix/store" = {
      device = nixStore.device;
      fsType = "btrfs";
      options = [
        "defaults"
        "subvol=nix-store"
        "rw"
        "noatime"
        "discard=async"
        # TODO: As much as i'd love a higher compression level fore the nix store - subvolume compression is not possible.
        # So we use zstd level 1 as the lowest common denominator. Uncomment if this is ever fixed
        #"compress=zstd:6"
        "compress=zstd:1"
        "ssd"
        "space_cache=v2"
      ];
      neededForBoot = true;
    };

    "/var/log" = {
      device = "/persist/var/log";
      fsType = "none";
      options = [ "bind" ];
      neededForBoot = true;
    };


    "/nix/store" = {
      device = "/persist/nix/store";
      fsType = "none";
      options = [ "bind" ];
      neededForBoot = true;
    };
  } // (persist-directories [
    # Where fprint fingerprint data lives
    "/var/lib/fprint"

    "/root"

    # Where NetworkManager stores WiFi info (and other connection types)
    "/etc/NetworkManager/system-connections"
    # Where wpa_supplicant stores WiFi info
    "/etc/wpa_supplicant"
    # Where iwd stores WiFi info
    "/var/lib/iwd"

    "/var/lib/bluetooth"

    # This is where waydroid stores its files such as images and configs - If you use waydroid, that is
    "/var/lib/waydroid"

    # Without this you'd have to keep approving each newly generated SSH on each boot if you enable SSHing into the machine
    "/etc/ssh"

    "/etc/nixos"

    "/etc/nix"

    "/home"

    "/etc/shadow"

    # Makes a bunch of measurements which it seems to read upon reboot. Probably worth it for battery useage purposes?
    "/var/cache/powertop"
  ]);
}
