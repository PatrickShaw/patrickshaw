# Cross-platform user packages.
#
# Anything that is purely part of *my* interactive environment belongs here
# rather than in `environment.systemPackages`, so that it follows me to any
# machine (NixOS, nix-darwin, or plain Nix) without needing root.
{ pkgs, ... }: {
  home.packages = [
    pkgs.lua-language-server
    pkgs.tree-sitter
  ];
}
