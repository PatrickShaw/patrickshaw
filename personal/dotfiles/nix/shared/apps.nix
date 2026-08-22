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
  # poetry
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
  # tealdeer is the Rust tldr client — same `tldr <cmd>` interface as the reference
  # client but with a local cache, so it's near-instant
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

  # Shell history search. Was mcfly — swap the two lines below to go back
  # (and flip the init lines in zsh/shared/.zshrc + fish/shared/config.fish).
  atuin
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
  # Syntax-aware diffs. Wired up as `git dft` / `git difftool -t difftastic`
  # in dotfiles/.gitconfig, so it stays opt-in alongside delta
  difftastic
  # Jujutsu — git-compatible VCS. Colocates with existing git repos via
  # `jj git init --colocate`, so it can be trialled without converting anything
  jujutsu

  # Nicer wrapper around nixos-rebuild/darwin-rebuild with a build-output diff.
  # The hand-written rebuild scripts still work — this is additive
  nh

  nickel

  go


  # Fairly generic CoW deduper
  pkgs.fclones
]
