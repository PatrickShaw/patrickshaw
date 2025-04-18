{ pkgs, ... }: {
  environment.systemPackages = import ./apps.nix { pkgs = pkgs; };
}