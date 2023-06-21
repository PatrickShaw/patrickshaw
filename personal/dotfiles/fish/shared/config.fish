set fish_greeting

fish_add_path $HOME/.cargo/bin

# starship init fish | source

bind \cW backward-kill-word

if status is-interactive
  set -x LS_COLORS (dircolors -c $HOME/.dircolors)
  zoxide init fish | source
  thefuck --alias | source  
  fnm env --shell fish --use-on-cd | source
  fnm completions --shell fish | source
end
