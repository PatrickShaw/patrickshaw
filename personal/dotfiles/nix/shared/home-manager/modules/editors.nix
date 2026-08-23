# Editors: VSCode/Cursor extensions plus the Neovim plugin set.
#
# The Neovim setup is deliberately file-based (pack/all/start + packadd)
# rather than using programs.neovim, so the same plugin set works no matter
# which nvim binary ends up first on PATH.
{ inputs, dracula-dircolors, git-rainbow-delimiters-nvim }:
{ config, lib, pkgs, ... }:
let
  vscode-extensions = inputs.vscode-extensions-2.extensions.${pkgs.stdenv.hostPlatform.system};

  my-vscode-extensions = with vscode-extensions.vscode-marketplace; [
    catppuccin.catppuccin-vsc
    vscode-icons-team.vscode-icons
    kubukoz.nickel-syntax

    # === JS
    dbaeumer.vscode-eslint
    stylelint.vscode-stylelint
    # Fails to build
    # oxc.oxc-vscode
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
in {
  programs.vscode = {
    enable = true;
    profiles.default.extensions = my-vscode-extensions;
  };

  programs.cursor = {
    enable = true;
    profiles.default.extensions = my-vscode-extensions;
  };

  home.file = let
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
}
