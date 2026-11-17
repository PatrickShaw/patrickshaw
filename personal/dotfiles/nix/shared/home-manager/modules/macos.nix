{ config, lib, pkgs, ... }:
let
  dotfiles = ../../../../macos;
  dockerSettings = "${pkgs.python3}/bin/python3 ${dotfiles}/docker-settings.py --preferences ${dotfiles}/docker-settings.json";
in {
  config = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    targets.darwin.defaults = builtins.fromJSON (builtins.readFile (dotfiles + "/preferences.json"));

    xdg.configFile."macos-setup".source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/personal/dotfiles/macos";

    # Check before the write boundary rather than failing halfway through activation.
    home.activation.checkDockerSettings = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
      ${dockerSettings} --check
    '';
    home.activation.applyDockerSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${dockerSettings}
    '';
  };
}
