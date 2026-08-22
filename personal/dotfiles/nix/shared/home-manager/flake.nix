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

    flake = let
      sharedModule = { pkgs, ... }: {
        config = {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.pshaw = { config, lib, ... }: let
              vscode-extensions = inputs.vscode-extensions-2.extensions.${pkgs.stdenv.hostPlatform.system};

              my-vscode-extensions = with vscode-extensions.vscode-marketplace; [
                  catppuccin.catppuccin-vsc
                  vscode-icons-team.vscode-icons
                  kubukoz.nickel-syntax

                  # === JS
                  dbaeumer.vscode-eslint
                  stylelint.vscode-stylelint
                  oxc.oxc-vscode
                  biomejs.biome
                  esbenp.prettier-vscode

                  denoland.vscode-deno

                  # Nix
                  bbenoist.nix

                  thenuprojectcontributors.vscode-nushell-lang
                  eww-yuck.yuck
                  arcanis.vscode-zipfs

                  rust-lang.rust-analyzer

                  # Found this one to be buggy:
                  # mkhl.direnv

                  eamodio.gitlens

                  ms-azuretools.vscode-docker

                  tamasfe.even-better-toml
                  redhat.vscode-yaml

                  streetsidesoftware.code-spell-checker
                  streetsidesoftware.code-spell-checker-australian-english
                  streetsidesoftware.code-spell-checker-british-english

                  # Contains OLED ayu
                  binary-ink.dark-modern-oled-theme-set
                ];
            in lib.recursiveUpdate {
                programs.direnv = {
                  enable = true;
                  enableBashIntegration = true;
                  enableFishIntegration = true;
                  enableNushellIntegration = true;
                  enableZshIntegration = true;
                  nix-direnv = {
                    enable = true;
                  };
                };
              } {
              imports = [
                # Supplies the prebuilt nix-index database used by programs.nix-index
                # below, so `nix-locate` works without a local index build
                inputs.nix-index-database.homeModules.nix-index
              ];
              home.packages = [
                pkgs.lua-language-server
                pkgs.tree-sitter
              ];
              programs.pay-respects.enable = true;
              programs.nix-index.enable = true;
              programs.vscode = {
                enable = true;
                profiles.default.extensions = my-vscode-extensions;
              };
              programs.cursor = {
                enable = true;
                profiles.default.extensions = my-vscode-extensions;
              };
                services.darkman = {
                  enable = !pkgs.stdenv.isDarwin;
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

                    # nvim-treesitter's `main` rewrite no longer ships parsers, and on
                    # this nixpkgs `nvim-treesitter.withAllGrammars` resolves to the exact
                    # same store path as the bare plugin (i.e. it's a no-op) - so without
                    # this there are zero parsers and treesitter highlighting is dead.
                    #
                    # Each nixpkgs grammar derivation exposes its shared library as
                    # `$out/parser`, but Neovim wants `parser/<lang>.so` on the
                    # runtimepath, so re-shape them into one plugin-like directory.
                    # Queries still come from nvim-treesitter itself, which is what keeps
                    # query and grammar versions in sync.
                    treesitter-parsers =
                      let
                        grammars = lib.filterAttrs
                          (_: v: lib.isDerivation v)
                          pkgs.vimPlugins.nvim-treesitter.builtGrammars;
                      in
                        pkgs.runCommand "nvim-treesitter-parsers" { } ''
                          mkdir -p $out/parser
                          ${lib.concatStringsSep "\n" (lib.mapAttrsToList
                            (name: grammar: "ln -s ${grammar}/parser $out/parser/${name}.so")
                            grammars)}
                        '';

                    # Some of these were taken form: https://github.com/mrcjkb/nvim-config/blob/b2cb412469bd4c2bf155976742cd2349f69a90ca/nix/plugin-overlay.nix#L15
                    plugins = map (item: "${item}") ([ treesitter-parsers ] ++ (with pkgs.vimPlugins; [
                      # Nix direnv integration
                      direnv-vim

                      # Syntax stuff
                      nvim-treesitter.withAllGrammars
                      nvim-lspconfig

                      # Hex color highlighting. 
                      nvim-colorizer-lua

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

                      # Icons come from mini.icons now (part of mini.nvim, above), which
                      # ships a nvim-web-devicons compatibility shim

                      # nvim-comment dropped: Neovim has built-in `gc`/`gcc` commenting
                      # since 0.10

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
                    ]));
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

                    ".config/nvim/lua/personal.lua".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/personal/dotfiles/nvim/shared/init.lua";
                    ".config/nvim/init.lua".text = initPackageLuaText + ''
                    
                      require("personal")
                    '';
                  } // nvimPackageLinks;
                };
                programs.fish = {
                  enable = true;
                  # Prompt is now starship (see fish/shared/config.fish). Uncomment
                  # the tide plugin below to switch back — its tide_* universal
                  # variables are still in ~/.config/fish/fish_variables.
                  plugins = [
                      # {
                      #     name = "tide";
                      #     src = pkgs.fishPlugins.tide.src;
                      # }
                  ];
                };
                programs.zsh = lib.recursiveUpdate {
                    enable = true;
                    initContent = lib.mkMerge [
                       (lib.mkOrder 500 ''
                        ${zsh-config}
                      '')
                    ];
                } (
                # if pkgs.stdenv.isDarwin then 
                {
                  # See: https://github.com/nix-darwin/nix-darwin/issues/554#issuecomment-1289736477
                  # completionInit = "autoload -U compinit && compinit -u";

                  # See: https://gemini.google.com/app/8cd64085d98f0bb4
                  completionInit = "";
                } 
                # else {}
              );
            };
          };
        };
      };
    in {
      nixosModules.default = sharedModule;
      darwinModules.default = sharedModule;
      };
    };
}
