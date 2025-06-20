set fish_greeting

fish_add_path $HOME/.cargo/bin

# starship init fish | source


if status is-interactive
  bind \cW backward-kill-word

  set -x LS_COLORS (dircolors -c $HOME/.dircolors)
  
  zoxide init fish | source

  pay-respects fish --alias | source
  #fnm env --shell fish --use-on-cd --corepack-enabled | source
  #fnm completions --shell fish | source
  mcfly init fish | source
end
