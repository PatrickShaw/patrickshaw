# Per-user services and small user-scoped programs.
#
# These are deliberately user services rather than system services: they only
# ever matter for a logged-in session, and running them per-user keeps them
# isolated from other accounts on the machine.
{ config, lib, pkgs, ... }: {
  # ActivityWatch stays entirely local. The Linux package is a
  # wrapper around aw-server-rust, aw-qt, and the window/AFK
  # watchers. The nixpkgs package is Linux-only, so macOS still needs
  # the official app bundle installed separately.
  systemd.user.services.activitywatch = lib.mkIf (!pkgs.stdenv.hostPlatform.isDarwin) {
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

  launchd.agents.activitywatch = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
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

  xdg.configFile."grounded-refresh" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/code/me/public/personal/dotfiles/grounded";
  };

  launchd.agents.grounded-refresh = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.python3}/bin/python3"
        "${config.xdg.configHome}/grounded-refresh/refresh.py"
      ];
      EnvironmentVariables = {
        PATH = lib.makeBinPath [ pkgs.nodejs pkgs.git pkgs.gh ] + ":/usr/bin:/bin";
        PYTHONDONTWRITEBYTECODE = "1";
      };
      WorkingDirectory = config.home.homeDirectory;
      StartCalendarInterval = { Weekday = 0; Hour = 10; Minute = 0; };
      RunAtLoad = false;
      KeepAlive = false;
      ProcessType = "Background";
      LowPriorityIO = true;
      Nice = 10;
      # Allow the runner to stop npx's children before launchd kills the parent.
      ExitTimeOut = 30;
      Umask = 63;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/grounded-refresh.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/grounded-refresh.error.log";
    };
  };

  services.darkman = {
    enable = !pkgs.stdenv.hostPlatform.isDarwin;
    settings = {
      usegeoclue = true;
    };
  };

  programs.pay-respects.enable = true;
  programs.nix-index.enable = true;
}
