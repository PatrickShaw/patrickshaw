# The cross-platform Home Manager profile.
#
# This is a *plain Home Manager module*: it says nothing about which user it
# belongs to and nothing about NixOS or nix-darwin. Hosts decide the user by
# importing it into `home-manager.users.<name>.imports`, and it can equally be
# consumed by a standalone `homeConfigurations` entry on a non-NixOS machine.
{ inputs, zsh-config, dracula-dircolors, git-rainbow-delimiters-nvim }:
{ ... }: {
  imports = [
    # Supplies the prebuilt nix-index database used by programs.nix-index,
    # so `nix-locate` works without a local index build
    inputs.nix-index-database.homeModules.nix-index

    (import ./shells.nix { inherit zsh-config; })
    (import ./editors.nix { inherit inputs dracula-dircolors git-rainbow-delimiters-nvim; })
    ./environment.nix
    ./packages.nix
    ./services.nix
    ./dotfiles.nix
  ];
}
