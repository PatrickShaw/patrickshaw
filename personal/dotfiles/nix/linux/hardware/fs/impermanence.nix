{ boot, persist, nixStore, isServer ? false }:
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

    # The new nixos overlay setting doesn't work with /etc bind mounts so we persist .rw-etc which is where
    # mutated /etc files go these days
    "/.rw-etc" = {
      device = "/persist/.rw-etc";
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
  } // (persist-directories ([

    "/root"

    "/home"

    "/var/lib"

    # FHS explicitly says tmp files to be preserved for reboot so will do
    "/var/tmp"

    # I think dhcpcd has trouble on restart so keeping this here (/var/db/dhcpcd)?
    # Worth storing in case whatever network your on doesn't like you forgetting your IP
    "/var/db"

    "/opt"
  ] ++ (if isServer then [] else [
    # There's enough things in here that matter (E.g. powertop) that I think you're better off just keeping trac of the hole thing
    "/var/cache"
  ])));
}
