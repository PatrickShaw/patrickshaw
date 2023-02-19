source $HOME/personal/dotfiles/zsh/shared/.zshrc

if ! which code &>/dev/null; then
  alias code=$(which code-oss)
fi

echo "run"