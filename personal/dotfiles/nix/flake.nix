{
  inputs = {
    unstable-pkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    stable-pkgs.url = "github:nixos/nixpkgs/nixpkgs-22.05-darwin";
    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "unstable-pkgs";
  };

  outputs = { self, darwin, stable-pkgs, unstable-pkgs }:
  let
    pkgs = stable-pkgs;

    shared-configuration = import ../shared/configuration.nix {
      pkgs = pkgs;
    };
  in {
    darwinConfigurations.default = darwin.lib.darwinSystem {
      system = "x86_64-darwin";
      modules = [ ./configuration.nix ];
      inputs = { inherit darwin stable-pkgs unstable-pkgs shared-configuration; pkg = unstable-pkgs; };
    };
  };
}