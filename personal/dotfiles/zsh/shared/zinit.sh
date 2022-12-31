autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Custom zinit settings
zinit ice depth=1
zinit light romkatv/powerlevel10k

export NVM_AUTO_USE=true
export NVM_COMPLETION=true

export ZSH_AUTOSUGGEST_STRATEGY=(match_prev_cmd completion)

# zinit wait lucid light-mode for \
#   atload="_zsh_autosuggest_start; bindkey '\t' autosuggest-accept; bindkey '^[[A' history-beginning-search-backward; bindkey '^[[B' history-beginning-search-forward; " \
#     @zsh-users/zsh-autosuggestions \
#   atinit="zicompinit; zicdreplay" \
#     @zdharma/fast-syntax-highlighting \
#   blockf atpull='zinit creinstall -q .' \
#     @zsh-users/zsh-completions \
#   ajeetdsouza/zoxide \
#   @paulirish/git-open
  #@jeffreytse/zsh-vi-mode \
  #@lukechilds/zsh-nvm \
zinit snippet OMZ::plugins/git
zinit snippet OMZ::plugins/thefuck
zinit snippet OMZ::plugins/yarn

eval $(fnm completions --shell zsh)
eval "$(fnm env --use-on-cd)"
