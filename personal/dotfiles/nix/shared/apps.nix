{ pkgs, ... }:

with pkgs; [
  discord

  # Breaks in MacOS gcc
  cmake
  gnumake

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
  gnupg
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

  # zsh
  fish
  nushell

  postgresql

  coreutils

  libiconv
  google-cloud-sdk

  syncthing
]
