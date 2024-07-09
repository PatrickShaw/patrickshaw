path+=($HOME/.cargo/bin)

export PATH
source $(dirname $0)/powerlevel10k/index.sh
#eval "$(starship init zsh)"

# See: https://stackoverflow.com/questions/444951/zsh-stop-backward-kill-word-on-directory-delimiter
# autoload -U select-word-style
x-bash-backward-kill-word(){
    WORDCHARS='' zle backward-kill-word

}
zle -N x-bash-backward-kill-word
bindkey '^W' x-bash-backward-kill-word

x-backward-kill-word(){
    WORDCHARS='*?_-[]~\!#$%^(){}<>|`@#$%^*()+:?' zle backward-kill-word
}
zle -N x-backward-kill-word 
bindkey '\e^?' x-backward-kill-word

export ZSH_AUTOSUGGEST_STRATEGY=(match_prev_cmd completion)

source "$(dirname $0)/zsh_bindings.zsh"

fnm use --log-level quiet
eval "$(zoxide init zsh)"
eval "$(mcfly init zsh)"

alias ls=lsd
alias cd=z
alias back=z -

zsh-defer -c 'eval "$(thefuck --alias)"'
zsh-defer -c 'eval "$(fnm completions --shell zsh)"'
zsh-defer -c 'eval "$(fnm env --use-on-cd --corepack-enabled)"'
