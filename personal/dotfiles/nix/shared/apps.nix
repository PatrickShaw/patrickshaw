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
  #wezterm

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
  git
  git-lfs
  
  gnupg
  pinentry

  neovim
  unrar

  pkgs.starship

  # zsh
  fish
  nushell

  postgresql

  (uutils-coreutils.override {
    prefix = "";
  })

  libnotify

  libiconv
  google-cloud-sdk

  rWrapper

  android-tools
  arduino-cli

  openssl

  git-open

  nickel

  libreoffice-fresh

  rust-analyzer

  efibootmgr

  go
]
