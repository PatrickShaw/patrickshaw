#!/bin/bash
set -euo pipefail

if [[ "$(uname -s)" != Darwin ]]; then
  printf 'These defaults are only supported on macOS.\n' >&2
  exit 1
fi

if [[ "$EUID" -eq 0 ]]; then
  printf 'Run this as your normal user, without sudo.\n' >&2
  exit 1
fi

mouse_speed=1.5
trackpad_speed=3
scroll_reverser_domain=com.pilotmoon.scroll-reverser

# Keep these out of rebuilds so changing mice doesn't mean editing Nix.
defaults write NSGlobalDomain com.apple.mouse.linear -bool true
defaults write NSGlobalDomain com.apple.mouse.scaling -float "$mouse_speed"
defaults write NSGlobalDomain com.apple.trackpad.scaling -float "$trackpad_speed"
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool true
defaults write "$scroll_reverser_domain" InvertScrollingOn -bool true
defaults write "$scroll_reverser_domain" ReverseTrackpad -bool false

printf 'Mouse defaults saved. Restart Scroll Reverser and log out/in to apply them.\n'
