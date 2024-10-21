{ boot, root, nixStore }:

{
  fileSystems = {
    "/" = {
      device = root.device;
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

    "/tmp" = {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=3G" "mode=755" ];
    };

    "/boot" = {
      device = boot.device;
      fsType = "vfat";
      options = [ "defaults" "discard" 
      # See https://discourse.nixos.org/t/security-warning-when-installing-nixos-23-11/37636
      "umask=0077" 
      ];
    };

    "/nix/store" = {
      device = nixStore.device;
      fsType = "btrfs";
      options = [
        "defaults"
        "subvol=nix-store"
        "rw"
        "noatime"
        "discard=async"
        "compress=zstd:1"
        "ssd"
        "space_cache=v2"
      ];
      neededForBoot = true;
    };
  };
}
