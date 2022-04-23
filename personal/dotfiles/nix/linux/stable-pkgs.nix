{}:
let
    pkgsModule = import (builtins.fetchTarball https://github.com/NixOS/nixpkgs/archive/nixos-21.05.tar.gz);
in
 import ../shared/pkgs.nix {
     pkgsModule = pkgsModule;
 }
