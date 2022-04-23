{}:
let
    pkgsModule = import (builtins.fetchTarball https://github.com/NixOS/nixpkgs/archive/nixpkgs-21.11-darwin.tar.gz);
in
 import ../shared/pkgs.nix {
     pkgsModule = pkgsModule;
 }
