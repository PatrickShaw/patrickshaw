# Cross-platform user packages.
#
# Anything that is purely part of *my* interactive environment belongs here
# rather than in `environment.systemPackages`, so that it follows me to any
# machine (NixOS, nix-darwin, or plain Nix) without needing root.
#
# The genuinely minimal CLI set (git, ripgrep, fd, ...) deliberately stays in
# `environment.systemPackages` via shared/barebones-apps.nix, so that root and
# non-Home-Manager machines (installer ISO, routers) remain usable.
{ lib, pkgs, ... }: {
  home.packages = with pkgs; [
    lua-language-server
    tree-sitter

    discord

    # Node canvas doesn't work without Mac's default GCC
    #gcc
    cmake
    gnumake

    # Not ready yet
    # lapce
    bc
    alacritty
    # Ghostty is added per-platform below: nixpkgs only builds `ghostty` on
    # Linux, so macOS uses the prebuilt `ghostty-bin`
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

    starship

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
    gh
    # Agents launch this via ~/.rovo/mcp.json + ~/.codex/config.toml, borrowing
    # `gh auth token` so there's no PAT sitting in the dotfiles
    github-mcp-server
    # Syntax-aware diffs. Wired up as `git dft` / `git difftool -t difftastic`
    # in dotfiles/.gitconfig, so it stays opt-in alongside delta
    difftastic
    # Jujutsu — git-compatible VCS. Colocates with existing git repos via
    # `jj git init --colocate`, so it can be trialled without converting anything
    jujutsu

    # Nicer wrapper around nixos-rebuild/darwin-rebuild with a build-output diff.
    # The hand-written rebuild scripts still work — this is additive
    nh

    # nixos-rebuild but with rollbacks
    deploy-rs

    nickel

    go

    # Fairly generic CoW deduper
    fclones
  ] ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
    iterm2

    # `ghostty` proper is Linux-only in nixpkgs (meta.platforms excludes darwin),
    # so macOS gets the prebuilt universal binary instead
    ghostty-bin
    # This one's app doesn't seem to ever appear
    # Using brew instead
    # rectangle
  ];
}
