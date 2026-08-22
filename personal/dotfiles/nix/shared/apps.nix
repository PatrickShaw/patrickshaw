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
  # Ghostty is added per-platform: nixpkgs only builds `ghostty` on Linux, so
  # macOS uses the prebuilt `ghostty-bin` (see ../linux/apps.nix and ../osx/apps.nix)
  # Dropped wezterm — alacritty + ghostty cover it

  nodejs
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
  # Replaced tldr with tealdeer - Faster
  # tldr
  tealdeer
  cheat

  bottom
  glances
  
  hyperfine
  
  gping
  
  procs

  curlie
  xh

  # dogdns replacement:
  doggo

  sd

  dust

  duf

  broot
  # Trialling yazi alongside broot as a TUI file manager
  yazi

  choose

  atuin
  # Using atuin now
  # mcfly

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


  # Fairly generic CoW deduper
  pkgs.fclones
]
