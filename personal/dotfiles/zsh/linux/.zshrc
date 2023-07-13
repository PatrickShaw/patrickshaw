source $HOME/personal/dotfiles/zsh/shared/.zshrc

# See: https://github.com/keybase/keybase-issues/issues/2798
export GPG_TTY=$(tty)

if ! which code &>/dev/null; then
  alias code=$(which code-oss)
fi

echo "run"