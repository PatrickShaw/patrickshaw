set fish_greeting

fish_add_path $HOME/.cargo/bin

if status is-interactive
  # Prompt: starship. This runs after conf.d/, so it takes over fish_prompt and
  # fish_right_prompt from tide if the tide plugin is ever re-enabled.
  set -gx STARSHIP_CONFIG "$HOME/.config/starship/starship.toml"
  starship init fish | source

  set -x LS_COLORS (dircolors -c $HOME/.dircolors)
  
  zoxide init fish | source

  pay-respects fish --alias | source
  #fnm env --shell fish --use-on-cd --corepack-enabled | source
  #fnm completions --shell fish | source

  atuin init fish --disable-up-arrow | source
  # Superceded by atuin:
  #mcfly init fish | source
end
