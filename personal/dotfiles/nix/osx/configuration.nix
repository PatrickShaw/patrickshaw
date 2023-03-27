{ config, pkgs, programs, users, environment, ... }:
let

  shared-configuration = import ../shared/configuration.nix { pkgs = pkgs; };

  sharedAliases = import ../shared/program-aliases.nix { };
in {
  programs.zsh.enable = true;
  imports = [
    ../shared/binary-caching.nix 
    shared-configuration
  ];

  services.nix-daemon.enable = true;
  environment.systemPackages = import ./apps.nix { pkgs = pkgs; };

  fonts = {
    fontDir.enable = true;
    fonts = import ../shared/font-pkgs.nix { pkgs = pkgs; };
  };
}
