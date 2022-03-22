{ config, pkgs, environment, ... }:

{
  imports = [
    ../shared/configuration.nix
  ];

  environment.systemPackages = import ./apps.nix { inherit pkgs; };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnfreePredicate = (pkg: true);
}
