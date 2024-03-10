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
    utils.url = "github:numtide/flake-utils";
    
    dracula-dircolors = {
      url = "github:dracula/dircolors";
      flake = false;
    };
  };
  
  outputs = {
      self,
      git-zsh-powerlevel10k,
      git-zsh-defer,
      git-zsh-autosuggestions,
      git-zsh-fast-syntax-highlighting,
      git-rainbow-delimiters-nvim,
      dracula-dircolors,
      utils,
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
      darwinModules.default = {pkgs, ...}: {
        imports = [self.nixosModules.default];
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
        };
      };
      nixosModules.default = {pkgs, ... }: {
        config = {
          environment.systemPackages = [
            pkgs.rnix-lsp
            pkgs.lua-language-server
            pkgs.tree-sitter
          ];
          home-manager = {
            users.pshaw = { config, lib, ... }: {

                services.darkman = {
                  enable = true;
                  settings = {
                    usegeoclue = true;
                  };
                };
                home = {
                  file = let
                    getLastPartOfPath = path:
                      let
                        parts = builtins.split "/" path;
                      in
                        builtins.elemAt parts (builtins.length parts - 1);

                    # Some of these were taken form: https://github.com/mrcjkb/nvim-config/blob/b2cb412469bd4c2bf155976742cd2349f69a90ca/nix/plugin-overlay.nix#L15
                    plugins = map (item: "${item}") (with pkgs.vimPlugins; [
                      # Nix direnv integration
                      direnv-vim

                      # Syntax stuff
                      nvim-treesitter.withAllGrammars
                      nvim-lspconfig

                      # Hex color highlighting
                      colorizer

                      # Auto complete
                      nvim-cmp
                      lspkind-nvim

                      git-rainbow-delimiters-nvim
                      indent-blankline-nvim

                      # Adds a bunch of pretty decent auto completes
                      vim-vsnip-integ
                      vim-vsnip
                      cmp-vsnip
                      friendly-snippets


                      git-blame-nvim
                      gitsigns-nvim

                      # Theme
                      catppuccin-nvim

                      which-key-nvim

                      # Auto complete
                      cmp-treesitter
                      cmp-git
                      cmp-path
                      cmp-nvim-lsp
                      cmp-nvim-lsp-document-symbol
                      # Needed for getting parameters to show in functions
                      lsp_signature-nvim
                      cmp-nvim-lsp-signature-help
                      cmp-buffer
                      cmp-rg
                      cmp-dap

                      nvim-autopairs

                      mini-nvim

                      vim-lastplace

                      # Sane word jumping
                      vim-wordmotion

                      vim-nix

                      # Gives icons to certain explorers
                      nvim-web-devicons

                      nvim-comment

                      # init.lua doco
                      neoconf-nvim

                      # Debugger adapter protocol
                      nvim-dap

                      # Code action lightbulb
                      nvim-lightbulb

                      # Search and replace
                      ssr-nvim

                      # Auto restore pending changes
                      auto-session
                    ]);
                    nvimPackageLinks = (builtins.listToAttrs (
                      map (item: {
                        name = ".config/nvim/pack/all/start/${getLastPartOfPath item}"; 
                        value = {
                          source = item;
                        };
                      }) plugins 
                    ));

                    initPackageLuaText = builtins.concatStringsSep "\n" (map (item: "vim.cmd [[packadd ${getLastPartOfPath item}]]") plugins);
                  in {
                    ".dircolors" = {
                      source = "${dracula-dircolors}/.dircolors";
                    };
                    ".config/direnv/direnvrc".source = pkgs.writeTextFile {
                      name = "direnvrc";
                      text = "source /run/current-system/sw/share/nix-direnv/direnvrc";
                      executable = true;
                    };

                    ".config/nvim/lua/personal.lua".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/personal/dotfiles/nvim/shared/init.lua";
                    ".config/nvim/init.lua".text = initPackageLuaText + ''
                    
                      require("personal")
                    '';
                  } // nvimPackageLinks;
                };
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
