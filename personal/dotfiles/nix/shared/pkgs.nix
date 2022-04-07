{ pkgsModule }:
let
  sharedAliases = import ./program-aliases.nix { };
  pkgs = pkgsModule {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (pkg: true);
    };
    programs = {
      git = {
        lfs.enable = true;
      };
      zsh = {
        enable = true;
        shellAliases = sharedAliases;
      };
      fish = {
        enable = true;
        shellAliases = sharedAliases;
      };
    };
  };
in
pkgs
