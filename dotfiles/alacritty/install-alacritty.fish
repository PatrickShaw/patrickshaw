#!/usr/bin/env fish
rm -r $HOME/.config/alacritty
ln -s -v (realpath (status dirname)) $HOME/.config/alacritty