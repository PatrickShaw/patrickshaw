{ root, nixStore }: {
  "${root.path}" = {
    device = root.device;
    fsType = "btrfs";
    options = [
      "defaults"
      "subvol=persist-root"
      "rw"
      "relatime"
      "discard=async"
      "compress=zstd:1"
      "space_cache=v2"
    ] ++ (if root.ssd ? true then ["ssd"] else []) ;
    neededForBoot = true;
  };
  "${nixStore.path}" = {
    device = nixStore.device;
    fsType = "btrfs";
    options = [
      "defaults"
      "subvol=nix-store"
      "rw"
      "noatime"
      "discard=async"
      "compress=zstd:6"
      "space_cache=v2"
    ] ++ (if nixStore.ssd ? true then ["ssd"] else []);
    neededForBoot = true;
  };
}