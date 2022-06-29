{}:
let
    pkgsModule = import (builtins.fetchTarball https://github.com/NixOS/nixpkgs/archive/nixpkgs-22.05-darwin.tar.gz);
in
    pkgsModule {
      config = {
        allowUnfree = true;
      };
    }
