#!/usr/bin/env fish
set fish_path (which fish)
# chsh -s $fish_path
source (status dirname)/install-fisher.fish
# fisher install jorgebucaran/fisher

fisher install ilancosman/tide@v5.0.1 edc/bass
