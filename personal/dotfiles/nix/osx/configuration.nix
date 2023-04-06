{ config, pkgs, programs, users, environment, ... }:
let
  sharedAliases = import ../shared/program-aliases.nix { };
in {
  programs.zsh.enable = true;
  imports = [
    ../shared/binary-caching.nix
    ../shared/configuration.nix
    ./base-configuration.nix
  ];
}
