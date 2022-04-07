{ pkgsModule }:
let
  sharedAliases = import ./program-aliases.nix { };
  pkgs = pkgsModule {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (pkg: true);
    };
    programs = {
      git = {
        enable = true;
        lfs.enable = true;
      };
      neovim = {
        enable = true;
        plugins = with pkgs.vimPlugins; [
          coc
          coc-nvim
          coc-css
          coc-yaml
          coc-python
          coc-git
          coc-rust-analyzer
          coc-tsserver
          vim-nix
        ];
      };
      zsh = {
        enable = true;
        shellAliases = sharedAliases;
      };
      fish = {
        enable = true;
        shellAliases = sharedAliases;
      };
    };
  };
in
pkgs
