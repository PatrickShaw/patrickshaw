{ config, pkgs, programs, environment, ... }:
let
  stable-pkgs = import ./stable-pkgs.nix {
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
  programs.zsh.enable = true;
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
