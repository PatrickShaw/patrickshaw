{ config, pkgs, stable-pkgs, programs, environment ... }:
let
  
  shared-configuration = import ../shared/configuration.nix {
    pkgs = pkgs;
  };

  sharedAliases = import ../shared/program-aliases.nix {};
in
{ 
  nixpkgs.overlays = [
    # Replace with our own set of pkgs
    (_: _: pkgs)
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
