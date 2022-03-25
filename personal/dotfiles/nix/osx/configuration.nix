{ config, pkgs, environment, ... }:

{
  imports = [
    ../shared/configuration.nix
  ];
  
  services.nix-daemon.enable = true;
  environment.systemPackages = import ./apps.nix { inherit pkgs; };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnfreePredicate = (pkg: true);
  
  fonts = {
    enableFontDir = true;
    fonts = import ../shared/font-pkgs.nix { inherit pkgs; };
 };
}
