{
  inputs = {
    git-zsh-powerlevel10k = {
      url = "github:romkatv/powerlevel10k";
      flake = false;
    };
    git-zsh-defer = {
      url = "github:romkatv/zsh-defer";
      flake = false;
    };
    git-zsh-autosuggestions= {
      url = "github:zsh-users/zsh-autosuggestions";
      flake = false;
    };
    git-zsh-fast-syntax-highlighting = {
      url = "github:zdharma-continuum/fast-syntax-highlighting";
      flake = false;
    };
    utils.url = "github:numtide/flake-utils";
  };
  
  outputs = {
      self,
      git-zsh-powerlevel10k,
      git-zsh-defer,
      git-zsh-autosuggestions,
      git-zsh-fast-syntax-highlighting,
      utils
  }:
    let
      zsh-config = import ./zsh-initExtra.nix {
        inherit
          git-zsh-powerlevel10k
          git-zsh-defer
          git-zsh-autosuggestions
          git-zsh-fast-syntax-highlighting;
      };
    in {
      nixosModules.default = {pkgs, ... }: {
        config = {
          home-manager = {
            users.pshaw = { config, lib, ... }: {
                programs.fish = {
                  enable = true;
                  plugins = [
                      {
                          name = "tide";
                          src = pkgs.fishPlugins.tide.src;
                      }
                  ];
                };
                programs.zsh = {
                    enable = true;
                    initExtra = ''
                      ${zsh-config}
                    '';
                };
            };
          };
        };
      };
    };
}
