{ pkgs, ... }:

with pkgs; [
  discord

  vscode  
  alacritty

  fnm

  yarn
  rustup
  python3
  python
  adoptopenjdk-bin
  poetry
  deno

  bat

  exa
  thefuck
  zoxide
  delta
  vscode
  git
  git-lfs
  delta
  neovim

  pkgs.vimPlugins."coc-nvim"
  pkgs.vimPlugins."coc-css"
  pkgs.vimPlugins."coc-yaml"
  pkgs.vimPlugins."coc-python"
  pkgs.vimPlugins."coc-git"
  pkgs.vimPlugins."coc-rust-analyzer"
  pkgs.vimPlugins."coc-tsserver"
  pkgs.vimPlugins."vim-nix"

  pkgs.starship

  zsh
  fish

  postgresql

  coreutils
]
