#!/usr/bin/env fish
set fish_path (which fish)
sudo sh -c "echo $fish_path >> /etc/shells"
# chsh -s $fish_path
source (status dirname)/../install-fisher.fish
# fisher install jorgebucaran/fisher

fisher install ilancosman/tide@v5.0.1 FabioAntunes/fish-nvm edc/bass
