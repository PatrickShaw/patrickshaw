#!/usr/bin/env fish

upower --show-info $(upower -e | grep battery) | grep icon-name | sd '^[^\']+' '' | sd '\'' ''