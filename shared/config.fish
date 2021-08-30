set fish_greeting

zoxide init fish | source

eval (ssh-agent -c) &> /dev/null

source (status dirname)/aliases/docker-aliases.fish
source (status dirname)/aliases/git-aliases.fish

source (status dirname)/aliases/program-aliases.fish

bind \cW backward-kill-word

thefuck --alias | source