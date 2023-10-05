#!/usr/bin/env fish
upower --show-info $(upower -e | grep battery) | grep percentage | sd '[^\d]+' '$1'
