#!/usr/bin/env fish
rm -r $HOME/.config/waybar
ln -s -v (realpath (status dirname)) $HOME/.config/waybar