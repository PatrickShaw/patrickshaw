{ pkgs, ... }: {
  services.nix-daemon.enable = true;
  environment.systemPackages = import ./apps.nix { pkgs = pkgs; };

  fonts = {
    fontDir.enable = true;
    fonts = import ../shared/font-pkgs.nix { pkgs = pkgs; };
  };
}