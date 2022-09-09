{ config, pkgs, stable-pkgs, programs, environment, ... }:
let
  
  shared-configuration = import ../shared/configuration.nix {
    pkgs = pkgs;
  };

  sharedAliases = import ../shared/program-aliases.nix {};
in
{ 
  pkgs.overlays = [
    (_: _: {
      deno = stable-pkgs.deno; # Depends on tcc
      tcc = stable-pkgs.tcc; # Broken
    })
  ];
  programs.zsh.enable = true;
  imports = [
    shared-configuration
  ];

  services.nix-daemon.enable = true;
  environment.systemPackages = import ./apps.nix { pkgs = pkgs; };
  
  fonts = {
    fontDir.enable = true;
    fonts = import ../shared/font-pkgs.nix { pkgs = pkgs; };
 };
}
