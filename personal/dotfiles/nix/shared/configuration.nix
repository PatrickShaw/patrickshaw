{ pkgs, programs, ... }:
let 
  stable = import (builtins.fetchTarball https://github.com/NixOS/nixpkgs/archive/nixpkgs-21.11-darwin.tar.gz) {
    config = {
      allowUnfree = true;
    };
  };
  sharedAliases = {
    ls = "exa";
    cd = "z";
    vim = "nvim";
    vi = "nvim";
  };
in
{
    nixpkgs.config.allowUnfree = true;
    nixpkgs.config.allowUnfreePredicate = (pkg: true);
 
    environment.systemPackages = import ./apps.nix { pkgs = stable.pkgs; };

    services.nix-daemon.enable = true;

    programs = {
        zsh = {
          enable = true;
          # TODO: dunno why this doesn't work: shellAliases = sharedAliases;
        };
        fish = {
          enable = true;
          shellAliases = sharedAliases;
        };
    };

  environment.shellAliases = sharedAliases;
  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}