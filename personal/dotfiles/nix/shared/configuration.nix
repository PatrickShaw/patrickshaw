# Settings that should apply everywhere (NixOS + nix-darwin).
# Anything platform specific belongs in ../linux or ../osx instead.
{ pkgs, ... }: let
  inherit (pkgs) lib;
in {
  environment.shells = [ pkgs.fish pkgs.zsh ];

  # Only the minimal CLI set stays system-wide, so root and machines without a
  # Home Manager profile (installer ISO, routers) still work. Everything else
  # is installed per-user - see shared/home-manager/modules/packages.nix.
  environment.systemPackages = import ./barebones-apps.nix { pkgs = pkgs; };

  # Session variables and shell aliases are user preferences and now live in
  # shared/home-manager/modules/environment.nix. That also removes the
  # nix-darwin /etc/zshrc alias workaround that used to be needed here.
  # See https://github.com/nix-darwin/nix-darwin/issues/886

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
