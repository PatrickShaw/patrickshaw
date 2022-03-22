{ pkgs, programs, ... }:
let 
  sharedAliases = {
    ls = "exa";
    cd = "z";
  };
in
{
    nixpkgs.config.allowUnfree = true;
    nixpkgs.config.allowUnfreePredicate = (pkg: true);
 
    environment.systemPackages = import ./apps.nix { inherit pkgs; };

    services.nix-daemon.enable = true;

    programs = {
        zsh = {
          enable = true;
          # TODO: dunno why this doesn't work: shellAliases = sharedAliases;
        };
        fish = {
          enable = true;
          shellAliases = sharedAliases;
        };
    };

  environment.shellAliases = sharedAliases;
  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}