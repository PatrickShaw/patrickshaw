set fish_greeting

# Note: PATH entries are declared via Nix these days

# nix-direnv devshells export the stdenv build sandbox's scratch directory as
# $TMPDIR. Nothing owns that directory once the shell that created it exits, so
# the OS temp reaper eventually deletes it while we are still pointing at it.
# Every mktemp-based tool then fails, including fish's `psub` -- which
# `starship init fish` depends on, taking out the rest of this file with it.
if set -q TMPDIR; and not test -d "$TMPDIR"
  # macOS expects its per-user directory under /var/folders. getconf does not
  # know this variable on Linux, where /tmp is the correct default.
  set -l platform_tmpdir (getconf DARWIN_USER_TEMP_DIR 2>/dev/null)
  test -d "$platform_tmpdir"; or set platform_tmpdir /tmp

  set -gx TMPDIR $platform_tmpdir
  set -gx TMP $platform_tmpdir
  set -gx TEMP $platform_tmpdir
  set -gx TEMPDIR $platform_tmpdir
  set -e NIX_BUILD_TOP
end

if status is-interactive
  # Prompt: starship. This runs after conf.d/, so it takes over fish_prompt and
  # fish_right_prompt from tide if the tide plugin is ever re-enabled.
  starship init fish | source

  # See: https://fishshell.com/docs/current/cmds/bind.html
  bind ctrl-w backward-kill-word

  set -gx LS_COLORS (dircolors -c $HOME/.dircolors)

  zoxide init fish | source

  pay-respects fish --alias | source
  #fnm env --shell fish --use-on-cd --corepack-enabled | source
  #fnm completions --shell fish | source

  atuin init fish --disable-up-arrow | source
  # Superceded by atuin:
  #mcfly init fish | source
end
