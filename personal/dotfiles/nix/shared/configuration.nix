{ pkgs, programs, ... }:
let 
  sharedAliases = {
    ls = "exa";
    # Unfortunately zoxide relies on cd in Fish so can't do: cd = "z";
    vim = "nvim";
    vi = "nvim";
  };
in
{
    nixpkgs.config.allowUnfree = true;
    nixpkgs.config.allowUnfreePredicate = (pkg: true);
 
    environment.systemPackages = import ./apps.nix { inherit pkgs; };

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