{ config, pkgs, programs, environment, ... }:
let
  stable-pkgs = import (builtins.fetchTarball https://github.com/NixOS/nixpkgs/archive/nixpkgs-21.11-darwin.tar.gz) {
    config = {
      allowUnfree = true;
    };
  };
  
  unstable-pkgs = import ./unstable-pkgs.nix {};
  default-pkgs = unstable-pkgs;

  shared-configuration = import ../shared/configuration.nix {
    pkgs = default-pkgs;
  };
in
{
  imports = [
    shared-configuration
  ];

  services.nix-daemon.enable = true;
  environment.systemPackages = import ./apps.nix { pkgs = default-pkgs; };
  
  fonts = {
    enableFontDir = true;
    fonts = import ../shared/font-pkgs.nix { pkgs = default-pkgs; };
 };
}
