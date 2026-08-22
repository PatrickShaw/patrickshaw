{ pkgs }:

with pkgs; [
  iterm2

  # `ghostty` proper is Linux-only in nixpkgs (meta.platforms excludes darwin),
  # so macOS gets the prebuilt universal binary instead
  ghostty-bin
  # This one's app doesn't seem to ever appear
  # Using brew instead
  # rectangle
]
