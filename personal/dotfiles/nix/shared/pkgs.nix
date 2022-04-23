{ pkgsModule }:
let
  sharedAliases = import ./program-aliases.nix { };
  pkgs = pkgsModule {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (pkg: true);
    };
  };
in
pkgs
