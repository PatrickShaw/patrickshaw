#!/usr/bin/env fish
rm -r $HOME/.config/gtk-3.0
ln -s -v (realpath (status dirname)) $HOME/.config/gtk-3.0
