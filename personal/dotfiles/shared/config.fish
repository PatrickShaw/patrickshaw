set fish_greeting

bind \cW backward-kill-word

if status is-interactive
  zoxide init fish | source
  thefuck --alias | source  
end

fnm env --use-on-cd | source
fnm completions --shell fish | source
