{ config, pkgs, programs, environment, ... }:
let
  stable-pkgs = import ./stable-pkgs.nix {};  
  unstable-pkgs = import ./unstable-pkgs.nix {};

  default-pkgs = unstable-pkgs;

  shared-configuration = import ../shared/configuration.nix {
    pkgs = pkgs;
  };

  sharedAliases = import ../shared/program-aliases.nix {};
in
{ 
  nixpkgs.overlays = [
    # Replace with our own set of pkgs
    (_: _: default-pkgs)
    (_: prev: {
      xcode-install = stable-pkgs."xcode-install";
      iterm2 = stable-pkgs.iterm2;
    })
  ];
  programs.zsh.enable = true;
  imports = [
    shared-configuration
  ];

  services.nix-daemon.enable = true;
  environment.systemPackages = import ./apps.nix { pkgs = pkgs; };
  
  fonts = {
    enableFontDir = true;
    fonts = import ../shared/font-pkgs.nix { pkgs = pkgs; };
 };
}
