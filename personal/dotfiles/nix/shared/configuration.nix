{ pkgs, ... }:
{ 
  environment.shells = [pkgs.fish pkgs.zsh];
  environment.systemPackages = import ./apps.nix { pkgs = pkgs; };
  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
