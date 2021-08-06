#!/usr/bin/env fish

set fonts_dir (realpath (status dirname)/../fonts)

for font_dir in $fonts_dir/*
    set folder_name (basename $font_dir)
        
    sudo ln -s $font_dir  /usr/share/fonts/
end

sudo ln -s (realpath (status dirname)/default-font.conf) /etc/fonts/conf.d/

sudo xbps-reconfigure -f fontconfig