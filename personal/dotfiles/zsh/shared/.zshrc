# See: https://stackoverflow.com/questions/444951/zsh-stop-backward-kill-word-on-directory-delimiter
autoload -U select-word-style
select-word-style bash

path+=($HOME/.cargo/bin)

export PATH
source $(dirname $0)/powerlevel10k/index.sh
#eval "$(starship init zsh)"

source $(dirname $0)/zinit.sh
eval $(thefuck --alias)
