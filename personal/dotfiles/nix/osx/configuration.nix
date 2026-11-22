{ config, pkgs, programs, users, environment, ... }: {
  programs.zsh.enable = true;

  # power.sleep.display applies one value to both power sources.
  system.activationScripts.power.text = ''
    /bin/bash ${../../macos/display-sleep.sh}
  '';
  imports = [
    ../shared/binary-caching.nix
    ../shared/configuration.nix
    # Disabled until nix-darwin supports the current Karabiner package layout.
    # https://github.com/nix-darwin/nix-darwin/issues/1041
    # ./karabiner.nix
  ];
}
