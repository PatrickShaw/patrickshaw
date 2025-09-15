{ pkgs, ... }:
with pkgs; (import ./barebones-apps.nix { inherit pkgs; }) ++ [
  discord

  # Node canvas doesn't work without Mac's default GCC
  #gcc
  cmake
  gnumake

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
  python3
  poetry
  uv
  
  # Just use direnv
  # deno

  gradle
  maven

  # Decided to go with lsd
  # Also see comments in https://news.ycombinator.com/item?id=37416430
  # eza
  
  gnupg

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

  sd

  du-dust

  duf

  broot

  choose

  mcfly

  # For managing workspaces
  jaq
  socat

  libnotify

  libiconv
  # Too large to be worth installing everywhere
  # google-cloud-sdk

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
