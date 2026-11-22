{ config, ... }: {
  services.karabiner-elements.enable = true;

  home-manager.users.${config.system.primaryUser} = { config, ... }: {
    # Karabiner watches the directory; linking only karabiner.json breaks reloads.
    home.file.".config/karabiner".source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/personal/dotfiles/karabiner";
  };
}
