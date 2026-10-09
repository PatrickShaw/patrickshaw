# Login shells stay bash so anything automated over SSH (`ssh host '<cmd>'`,
# scp, rsync, deploy-rs) gets the shell it expects rather than fish. Only
# interactive sessions hop into fish. Works on NixOS and nix-darwin since both
# /etc/bashrc's bail out before interactiveShellInit for non-interactive shells.
{ lib, pkgs, ... }: {
  programs.fish.enable = true;

  # Checking the parent means typing `bash` from fish still gets you bash.
  # `*fish` because macOS reports a full path (or `-fish` for login shells).
  programs.bash.interactiveShellInit = ''
    if [[ $(ps -o comm= -p "$PPID") != *fish ]]; then
      if shopt -q login_shell; then
        exec ${lib.getExe pkgs.fish} --login
      else
        exec ${lib.getExe pkgs.fish}
      fi
    fi
  '';
}
