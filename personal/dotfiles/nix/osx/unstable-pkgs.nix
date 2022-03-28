{}:
let
    pkgsModule = import (builtins.fetchTarball https://github.com/NixOS/nixpkgs/archive/nixpkgs-unstable.tar.gz);
in
 import ../shared/pkgs.nix {
     pkgsModule = pkgsModule;
 }