{ pkgs, programs, ... }:
{
    nixpkgs.config.allowUnfree = true;
    nixpkgs.config.allowUnfreePredicate = (pkg: true);
 
    environment.systemPackages = import ./apps.nix { inherit pkgs; };

    services.nix-daemon.enable = true;

    programs = {
        zsh.enable = true;
        fish.enable = true;
    };
}