source $(dirname $0)/../shared/.zshrc

if ! which code &>/dev/null; then
  alias code=$(which code-oss)
fi
eval $(zoxide init zsh)
