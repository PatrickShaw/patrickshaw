# Settings that should apply everywhere (NixOS + nix-darwin).
# Anything platform specific belongs in ../linux or ../osx instead.
{ pkgs, ... }: let
  inherit (pkgs) lib;
  shared-aliases = import ./program-aliases.nix { };
in {
  environment.shells = [ pkgs.fish pkgs.zsh ];
  environment.systemPackages = import ./apps.nix { pkgs = pkgs; };
  environment.variables = {
    VISUAL = "nvim";
    TERMINAL = "ghostty";
    BROWSER = "firefox";

    # Priority 900: beats nix-darwin's own `mkDefault "nano"`, while still letting the more
    EDITOR = lib.mkOverride 900 "nvim";
    PAGER = "cat";

    # We don't use MCFLY but leaving this here cause harmless
    # See https://github.com/cantino/mcfly#fuzzy-searchingo.
    MCFLY_FUZZY = "2";
    MCFLY_HISTORY_LIMIT = "40000";
    MCFLY_PROMPT = "❯";
    MCFLY_RESULTS = "15";
  };

  # Applies to every shell (zsh + fish) on both platforms
  environment.shellAliases = shared-aliases;

  # nix-darwin's zsh module (unlike NixOS') doesn't apply environment.shellAliases to /etc/zshrc,
  # so replicate what the NixOS module does. No-op on Linux.
  # See https://github.com/nix-darwin/nix-darwin/issues/886
  programs.zsh.interactiveShellInit = lib.optionalString pkgs.stdenv.hostPlatform.isDarwin (
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: value: "alias ${name}=${lib.escapeShellArg value}") shared-aliases
    )
  );
  
  # Prefer to run this myself
  programs.zsh.enableGlobalCompInit = false;
  # We do this ourselves in the shared .zshrc
  programs.zsh.enableCompletion = false;

  nixpkgs.config.allowUnfree = lib.mkDefault true;

  # Be careful: If you do not add these flags to scripts that run nix commands, these commands will
  # fail for those who don't enable these flags via configurations.
  # mkDefault so the `barebones` module's normal-priority definition wins on NixOS.
  nix.settings.experimental-features = lib.mkDefault [ "flakes" "nix-command" ];

  nix.gc = {
    automatic = lib.mkDefault true;
    options = lib.mkDefault "--delete-older-than 30d";
  };
}
