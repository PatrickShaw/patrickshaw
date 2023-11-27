{ pkgs, ... }:

with pkgs; [
  discord

  # Node canvas doesn't work without Mac's default GCC
  #gcc
  cmake
  gnumake

  vscode
  # Not ready yet
  # lapce
  lapce

  alacritty
  #wezterm

  nodePackages.nodejs
  fnm
  yarn

  rustup
  rust-analyzer
  python3Full
  # Security flaw: python
  adoptopenjdk-bin
  poetry
  
  # Just use direnv
  # deno

  adoptopenjdk-bin
  gradle
  maven

  bat

  # Decided to go with lsd
  # Also see comments in https://news.ycombinator.com/item?id=37416430
  # eza
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

  # CLI based GTK dialog renderer - Similarish in purpose to Wofi
  yad

  (uutils-coreutils.override {
    prefix = "";
  })

  libnotify

  libiconv
  google-cloud-sdk

  # Just use direnv
  # cper

  android-tools
  arduino-cli

  openssl

  trash-cli

  git-open

  nickel

  libreoffice-fresh

  efibootmgr

  go
]
