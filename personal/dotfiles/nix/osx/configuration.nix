{ config, pkgs, programs, users, environment, ... }: {
  programs.zsh.enable = true;
  imports = [
    ../shared/binary-caching.nix
    ../shared/configuration.nix
  ];
}
