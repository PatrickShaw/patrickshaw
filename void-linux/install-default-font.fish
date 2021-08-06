#!/usr/bin/env fish

set fonts_dir (realpath (status dirname)/../fonts)

for font_dir in $fonts_dir/*
    set folder_name (basename $font_dir)
        
    sudo ln -s $font_dir  /usr/share/fonts/
end

# See: https://www.freedesktop.org/software/fontconfig/fontconfig-user.html
sudo ln -s (realpath (status dirname)/default-font.conf) /etc/fonts/conf.d/0-default-font.conf

sudo xbps-reconfigure -f fontconfig