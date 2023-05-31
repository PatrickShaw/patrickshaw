{
  git-zsh-powerlevel10k,
  git-zsh-defer,
  git-zsh-autosuggestions,
  git-zsh-fast-syntax-highlighting
}: ''
  source '${git-zsh-powerlevel10k}/powerlevel10k.zsh-theme';
  source '${git-zsh-defer}/zsh-defer.plugin.zsh';
  source '${git-zsh-autosuggestions}/zsh-autosuggestions.plugin.zsh';
  source '${git-zsh-fast-syntax-highlighting}/fast-syntax-highlighting.plugin.zsh';                
''
