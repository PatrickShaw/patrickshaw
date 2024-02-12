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
  bc
  alacritty
  #wezterm

  nodePackages.nodejs
  fnm
  yarn

  rustup
  # rust-analyzer
  python3Full
  # Security flaw: python
  poetry
  
  # Just use direnv
  # deno

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


  # Some great programs mentioned over at https://github.com/ibraheemdev/modern-unix
  tldr
  cheat

  bottom
  glances
  
  hyperfine
  
  gping
  
  procs

  curlie
  xh

  dogdns

  lsd

  sd

  du-dust

  duf

  broot
  
  fd

  ripgrep

  choose

  mcfly

  # For managing workspaces
  jaq
  socat

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

  go
]
