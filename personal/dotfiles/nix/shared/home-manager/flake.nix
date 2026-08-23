{
  inputs = {
    git-rainbow-delimiters-nvim = {
      url = "github:hiphish/rainbow-delimiters.nvim";
      flake = false;
    };
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
    # Uncommented for the following reason "If you install Powerlevel10k, you don't need to install gitstatus." See https://github.com/romkatv/gitstatus
    # gitstatus-repo = {
    #   url = "github:romkatv/gitstatus";
    #   flake = false;
    # };
    # flake-parts replaces the (previously unused) numtide/flake-utils input.
    # See: https://flake.parts
    flake-parts.url = "github:hercules-ci/flake-parts";

    # Ships a prebuilt nix-index database, so `nix-locate` / `programs.nix-index`
    # works immediately instead of needing a slow local index build.
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    dracula-dircolors = {
      url = "github:dracula/dircolors";
      flake = false;
    };

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Only needed for the standalone homeConfigurations below. When these
    # modules are consumed as part of a NixOS/nix-darwin system, that system's
    # own home-manager is used instead.
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    #vscode-extensions.url = "git+ssh://git@github.com:nix-community/nix-vscode-extensions.git"; #"github:nix-community/nix-vscode-extensions/master";
    vscode-extensions-2 = {
      url = "github:nix-community/nix-vscode-extensions";
      #url = "https://github.com/nix-community/nix-vscode-extensions/archive/refs/heads/master.zip";
      #url = "path:/home/pshaw/code/me/public/personal/dotfiles/nix/shared/home-manager/masters.zip";

      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  
  outputs = {
      self,
      flake-parts,
      git-zsh-powerlevel10k,
      git-zsh-defer,
      git-zsh-autosuggestions,
      git-zsh-fast-syntax-highlighting,
      git-rainbow-delimiters-nvim,
      dracula-dircolors,
      ...
  }@inputs:
    let
      zsh-config = import ./zsh-initExtra.nix {
        inherit
          git-zsh-powerlevel10k
          git-zsh-defer
          git-zsh-autosuggestions
          git-zsh-fast-syntax-highlighting;
      };
    in flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];

    # Exported as Home Manager modules rather than nixosModules/darwinModules.
    # Nothing in here needs system-level privileges, so wrapping it in an OS
    # module would only couple it to NixOS/nix-darwin and make the same config
    # unusable under a standalone `home-manager switch`.
    #
    # Hosts wire these up with:
    #   home-manager.users.<name>.imports = [ inputs.home-manager-config.homeModules.default ];
    flake = {
      homeModules = {
        default = import ./modules/shared.nix {
          inherit inputs zsh-config dracula-dircolors git-rainbow-delimiters-nvim;
        };

        # Linux desktop applications and session services. Kept separate so
        # headless Linux hosts and macOS don't pull in a desktop.
        linux-desktop = ./modules/linux-desktop.nix;

        # Public dotfile symlinks on their own, for users (e.g. root on
        # servers) that want the config links without the whole profile.
        dotfiles = ./modules/dotfiles.nix;
      };

      # Standalone entry points, for machines that just have Nix installed
      # (a work laptop, someone else's box, a container) rather than NixOS or
      # nix-darwin. Activate with:
      #   home-manager switch --flake .#pshaw@x86_64-linux
      #
      # These instantiate their own nixpkgs, so unlike the module path they
      # can't inherit nixpkgs.config from a system configuration and have to
      # set allowUnfree themselves.
      homeConfigurations =
        let
          mkHome = { system, username, modules }:
            inputs.home-manager.lib.homeManagerConfiguration {
              pkgs = import inputs.nixpkgs {
                inherit system;
                config.allowUnfree = true;
              };
              modules = modules ++ [
                {
                  home = {
                    inherit username;
                    homeDirectory =
                      if inputs.nixpkgs.lib.hasSuffix "darwin" system
                      then "/Users/${username}"
                      else "/home/${username}";
                    stateVersion = "23.05";
                  };
                }
              ];
            };

          shared = import ./modules/shared.nix {
            inherit inputs zsh-config dracula-dircolors git-rainbow-delimiters-nvim;
          };
        in {
          "pshaw@x86_64-linux" = mkHome {
            system = "x86_64-linux";
            username = "pshaw";
            modules = [ shared ./modules/linux-desktop.nix ];
          };
          "pshaw@aarch64-darwin" = mkHome {
            system = "aarch64-darwin";
            username = "pshaw";
            modules = [ shared ];
          };
        };
    };
  };
}
