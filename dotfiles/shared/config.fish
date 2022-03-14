set fish_greeting

eval (ssh-agent -c) &> /dev/null

source (status dirname)/aliases/docker-aliases.fish
source (status dirname)/aliases/git-aliases.fish

source (status dirname)/aliases/program-aliases.fish

bind \cW backward-kill-word

if status is-interactive
  zoxide init fish | source
  thefuck --alias | source  
end
