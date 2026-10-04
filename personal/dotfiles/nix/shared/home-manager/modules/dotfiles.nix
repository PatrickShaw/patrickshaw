# Out-of-store symlinks for the *public* dotfiles.
#
# Everything here points into `~/personal/...` (itself a link to the public
# half of the monorepo), so this module is safe to share and works standalone.
# Private links live in `private/nix/shared/config-links.nix`.
#
# Linux-only config directories (sway, river, eww, waybar, mako, ...) are
# linked unconditionally, including on macOS: they're inert there, and keeping
# one list is simpler than maintaining a per-platform split. Only paths that
# genuinely differ between platforms get an `isDarwin` branch.
#
# Dotfiles from someone who might have ADHD?
# But also uses xorg from what I can see
# https://github.com/Vaernil/dotfiles
{ config, lib, pkgs, ... }:
let
  link = path: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/${path}";

  # Each harness discovers skills from its own directory. Skills are linked
  # individually rather than owning the parent directories, since some of
  # those are also written to by work-managed skill installers.
  skillHarnessDirs = [ ".rovo" ".agents" ".claude" ".codex" ".cursor" ];

  # `sourceDir` is read from the flake source so adding a skill directory is
  # all it takes to get it linked everywhere, while `linkDir` (relative to
  # $HOME) keeps the links pointing at the live checkout.
  mkSkillLinks = { sourceDir, linkDir }:
    let
      skills = lib.attrNames (lib.filterAttrs (_: type: type == "directory")
        (builtins.readDir sourceDir));
    in lib.listToAttrs (lib.concatMap
      (skill: map
        (dir: lib.nameValuePair "${dir}/skills/${skill}" {
          source = link "${linkDir}/${skill}";
        })
        skillHarnessDirs)
      skills);
in {
  # Shared with the private config-links module so both halves link skills
  # into the same set of harnesses.
  lib.agentSkills.mkLinks = mkSkillLinks;

  home.file = {
    "monorepo".source = link "code/me/public/community";
    "community".source = link "code/me/public/community";
    "personal".source = link "code/me/public/personal";
    "me".source = link "code/me";
    #".config/zsh/.zshrc".source = config.lib.file.mkOutOfStoreSymlink ../../dotfiles/zsh/glados/.zshrc;
    #".config/fish/config.fish".source = config.lib.file.mkOutOfStoreSymlink ../../private/dotfiles/fish/glados/config.fish;
    ".config/starship".source = link "personal/dotfiles/starship";
    ".config/atuin".source = link "personal/dotfiles/atuin";
    ".config/sway".source = link "personal/dotfiles/sway";
    ".config/nu".source = link "personal/dotfiles/nu";
    #".config/nvim".source = link "personal/dotfiles/nvim/linux";
    ".config/waybar".source = link "personal/dotfiles/waybar";
    ".config/ghostty".source = link "personal/dotfiles/ghostty";
    ".config/broot".source = link "personal/dotfiles/broot";
    ".config/gtk-3.0/settings.ini".source = link "personal/dotfiles/.config/gtk-3.0/settings.ini";
    ".config/gtk-4.0".source = link "personal/dotfiles/gtk-4.0";
    ".config/river".source = link "personal/dotfiles/river";
    #".config/hypr".source = link "personal/dotfiles/hypr";
    ".config/eww".source = link "personal/dotfiles/eww";
    ".config/wofi".source = link "personal/dotfiles/.config/wofi";
    ".config/fuzzel".source = link "personal/dotfiles/.config/fuzzel";
    ".icons/default".source = link "personal/dotfiles/.icons/default"; # For Linux
    # See: https://github.com/elkowar/eww/issues/476#issuecomment-1229366913
    ".local/share/icons/default".source = link "personal/dotfiles/.local/share/icons/default"; # For Linux
    ".config/containers".source = link "personal/dotfiles/containers";
    ".config/helix".source = link "personal/dotfiles/helix/";
    ".config/electron-flags.conf".source = link "personal/dotfiles/.config/electron-flags.conf";
    ".config/code-flags.conf".source = link "personal/dotfiles/.config/code-flags.conf";
    ".config/codium-flags.conf".source = link "personal/dotfiles/.config/codium-flags.conf";
    ".config/user-dirs.locale".source = link "personal/dotfiles/.config/user-dirs.locale";
    ".config/mako/config".source = link "personal/dotfiles/mako/config";

    # mkDefault so a host can point this elsewhere (e.g. the work laptop's
    # .work-gitconfig) with a plain assignment rather than mkForce.
    ".gitconfig".source = lib.mkDefault (link "personal/dotfiles/.gitconfig");
  } // mkSkillLinks {
    sourceDir = ../../../../agents/skills;
    linkDir = "personal/dotfiles/agents/skills";
  } // (if pkgs.stdenv.hostPlatform.isDarwin then {
    "Library/Application Support/discord/settings.json".source = link "personal/dotfiles/discord/settings.json";
  } else {
    ".config/discord/settings.json".source = link "personal/dotfiles/discord/settings.json";
  });
}
