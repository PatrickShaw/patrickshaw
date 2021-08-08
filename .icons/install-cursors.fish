#!/usr/bin/env fish
rm -r $HOME/.icons
ln -s -v (realpath (status dirname)) $HOME/.icons
