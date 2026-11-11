# A long-running, headed Camoufox that agents drive through @playwright/mcp.
# See the camoufox skill for how the pieces fit together.
#
# macOS only for now since that's the only place it's been needed. Linux would
# want an equivalent systemd user service.
{ config, lib, pkgs, ... }:
let
  serverScript = "${config.home.homeDirectory}/personal/dotfiles/camoufox/server.py";
  # Outside the Nix store and outside any cache dir since it holds logins
  profileDir = "${config.xdg.dataHome}/camoufox/profile";
  logDir = "${config.home.homeDirectory}/Library/Logs";
  # launchd's PATH has no Python on it, so without this uv grabs whatever its
  # newest managed Python is. Keep in step with requires-python in server.py
  python = pkgs.python313;
in {
  launchd.agents.camoufox = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    enable = true;
    config = {
      # uv resolves the versions pinned inline in the script, so bumping
      # Camoufox is a script edit rather than a rebuild
      ProgramArguments = [
        "${pkgs.uv}/bin/uv"
        "run"
        "--python"
        "${python}/bin/python3"
        "--script"
        serverScript
        profileDir
      ];
      RunAtLoad = true;
      # Quitting the window is a clean exit and stays quit. Only crashes restart
      KeepAlive.SuccessfulExit = false;
      ProcessType = "Interactive";
      # Headed, so it has to live in the logged-in GUI session
      LimitLoadToSessionType = "Aqua";
      StandardOutPath = "${logDir}/camoufox.log";
      StandardErrorPath = "${logDir}/camoufox.error.log";
    };
  };
}
