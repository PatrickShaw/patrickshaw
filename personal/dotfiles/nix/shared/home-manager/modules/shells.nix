# Shell configuration (direnv + fish + zsh).
#
# User agnostic: this module only sets `programs.*`, so whichever user imports
# it gets the configuration. Nothing here assumes NixOS or nix-darwin, which
# means it also works under a standalone `home-manager switch`.
{ zsh-config }:
{ lib, pkgs, ... }: {
  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;
    enableZshIntegration = true;
    nix-direnv = {
      enable = true;
    };
  };

  programs.fish = {
    enable = true;
    # Prompt is now starship (see fish/shared/config.fish). Uncomment
    # the tide plugin below to switch back — its tide_* universal
    # variables are still in ~/.config/fish/fish_variables.
    plugins = [
      # {
      #     name = "tide";
      #     src = pkgs.fishPlugins.tide.src;
      # }
    ];
  };

  programs.zsh = {
    enable = true;
    initContent = lib.mkMerge [
      (lib.mkOrder 500 ''
        ${zsh-config}
      '')
    ];

    # See: https://github.com/nix-darwin/nix-darwin/issues/554#issuecomment-1289736477
    # completionInit = "autoload -U compinit && compinit -u";

    # See: https://gemini.google.com/app/8cd64085d98f0bb4
    completionInit = "";
  };
}
