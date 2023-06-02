{ pkgs, ... }: {
  environment.shells = [ pkgs.fish pkgs.zsh ];
  environment.systemPackages = import ./apps.nix { pkgs = pkgs; };
  # Be careful: If you do not add these flags to scripts that when running nix commands, these commands will fail for those who don't enable these flags via configurations
  nix.settings.experimental-features = [ "flakes" "nix-command" ];
  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
