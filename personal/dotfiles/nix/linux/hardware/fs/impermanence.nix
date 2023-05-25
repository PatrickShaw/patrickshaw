{ boot, persist, nixStore }:

{
  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=4G" "mode=755" ];
      neededForBoot = true;
    };

    "/boot" = {
      device = boot.device;
      fsType = "vfat";
      options = [ "defaults" "discard" ];
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
        "compress=zstd:6"
        "ssd"
        "space_cache=v2"
      ];
      neededForBoot = true;
    };

    "/nix/store" = {
      device = "/persist/nix/store";
      fsType = "none";
      options = [ "bind" ];
      neededForBoot = true;
    };

    "/root" = {
      device = "/persist/root";
      fsType = "none";
      options = [ "bind" ];
      neededForBoot = false;
    };

    "/etc/NetworkManager/system-connections" = {
      device = "/persist/etc/NetworkManager/system-connections";
      fsType = "none";
      options = [ "bind" ];
    };

    "/var/lib/bluetooth" = {
      device = "/persist/var/lib/bluetooth";
      fsType = "none";
      options = [ "bind" ];
    };

    # This is where waydroid stores its files such as images and configs - If you use waydroid, that is
    "/var/lib/waydroid" = {
      device = "/persist/var/lib/waydroid";
      fsType = "none";
      options = [ "bind" ];
    };

    # Without this you'd have to keep approving each newly generated SSH on each boot if you enable SSHing into the machine
    "/etc/ssh" = {
      device = "/persist/etc/ssh";
      fsType = "none";
      options = [ "bind" ];
    };

    "/var/log" = {
      device = "/persist/var/log";
      fsType = "none";
      options = [ "bind" ];
      neededForBoot = true;
    };

    "/etc/nixos" = {
      device = "/persist/etc/nixos";
      fsType = "none";
      options = [ "bind" ];
    };

    "/home" = {
      device = "/persist/home";
      fsType = "none";
      options = [ "bind" ];
    };

    "/etc/shadow" = {
      device = "/persist/etc/shadow";
      fsType = "none";
      options = [ "bind" ];
      # Verified: This isn't needed for boot
    };
  };
}
