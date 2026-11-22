{ config, pkgs, ... }:
let
  # The default build links the BUSL pipeline engine. We only want Apache-2.0
  # command filters, with no proxy or model-backed compression.
  rtk = pkgs.rtk.overrideAttrs {
    cargoBuildNoDefaultFeatures = true;
    cargoCheckNoDefaultFeatures = true;
  };
  claudeHook = pkgs.writeShellApplication {
    name = "rtk-claude-hook";
    runtimeInputs = [ pkgs.python3 rtk ];
    text = ''
      exec python3 "${config.home.homeDirectory}/personal/dotfiles/rtk/claude-hook.py"
    '';
  };
  configPath = if pkgs.stdenv.hostPlatform.isDarwin
    then "Library/Application Support/rtk/config.toml"
    else "${config.xdg.configHome}/rtk/config.toml";
in {
  home.packages = [ rtk claudeHook ];
  home.sessionVariables.RTK_TELEMETRY_DISABLED = "1";
  home.file.${configPath}.source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/personal/dotfiles/rtk/config.toml";
}
