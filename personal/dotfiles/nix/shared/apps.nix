{ pkgs, ... }:

with pkgs; [
  discord

  # Node canvas doesn't work without Mac's default GCC
  #gcc
  cmake
  gnumake

  vscode
  lapce
  
  alacritty
  wezterm

  fnm

  yarn
  rustup
  python3
  # Security flaw: python
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
  neovim
  unrar

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

  uutils-coreutils

  libiconv
  google-cloud-sdk

  syncthing

  rWrapper

  android-tools
  arduino-cli

  openssl

  git-open

  nickel

  direnv

  libreoffice-fresh
]
