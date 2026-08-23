# Per-user services and small user-scoped programs.
#
# These are deliberately user services rather than system services: they only
# ever matter for a logged-in session, and running them per-user keeps them
# isolated from other accounts on the machine.
{ config, lib, pkgs, ... }: {
  # ActivityWatch stays entirely local. The Linux package is a
  # wrapper around aw-server-rust, aw-qt, and the window/AFK
  # watchers. macOS uses the official app bundle installed by the
  # declarative Homebrew cask in private/nix/darwin/flake.nix.
  systemd.user.services.activitywatch = lib.mkIf (!pkgs.stdenv.isDarwin) {
    Unit = {
      Description = "ActivityWatch local workflow telemetry";
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.activitywatch}/bin/aw-qt";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  launchd.agents.activitywatch = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config = {
      # Launch by bundle name rather than relying on the app's
      # internal executable layout.
      ProgramArguments = [
        "/usr/bin/open"
        "-a"
        "ActivityWatch"
      ];
      RunAtLoad = true;
      KeepAlive = false;
      ProcessType = "Interactive";
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/activitywatch.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/activitywatch.error.log";
    };
  };

  services.darkman = {
    enable = !pkgs.stdenv.isDarwin;
    settings = {
      usegeoclue = true;
    };
  };

  programs.pay-respects.enable = true;
  programs.nix-index.enable = true;
}
