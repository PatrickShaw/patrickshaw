# See: https://stackoverflow.com/questions/444951/zsh-stop-backward-kill-word-on-directory-delimiter
autoload -U select-word-style
select-word-style bash

path+=($HOME/.cargo/bin)

export PATH
source $(dirname $0)/powerlevel10k/index.sh
#eval "$(starship init zsh)"

export ZSH_AUTOSUGGEST_STRATEGY=(match_prev_cmd completion)

source "$(dirname $0)/zsh_bindings.zsh"

fnm use --log-level quiet
eval "$(zoxide init zsh)"

alias ls=exa
alias cd=z
alias back=z -

zsh-defer -c 'eval "$(thefuck --alias)"'
zsh-defer -c 'eval "$(fnm completions --shell zsh)"'
zsh-defer -c 'eval "$(fnm env --use-on-cd)"'
