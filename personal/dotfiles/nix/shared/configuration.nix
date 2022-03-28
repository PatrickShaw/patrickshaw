{ pkgs, ... }:
{ 
  environment.shells = [pkgs.fish pkgs.zsh];
  environment.shellAliases = import ./program-aliases.nix {};
  environment.systemPackages = import ./apps.nix { pkgs = pkgs; };
  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
