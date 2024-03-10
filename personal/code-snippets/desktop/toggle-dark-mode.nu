#!/usr/bin/env nu

def main [mode: string] {
  let isLightMode = $mode in ["sunny"];
  let isDarkMode = not $isLightMode

  let gtkPrefer = if $isLightMode { 'prefer-light' } else { 'prefer-dark' }
  let gtkIconTheme = if $isLightMode { 'Papirus-Light' } else { 'Papirus-Dark' }

  gsettings set org.gnome.desktop.interface color-scheme $gtkPrefer
  gsettings set org.gnome.desktop.interface icon-theme $gtkIconTheme

  if ($isLightMode) {
    gsettings set org.gnome.desktop.interface gtk-theme 'Orchis-Green'
  } else {
    gsettings set org.gnome.desktop.interface gtk-theme 'Orchis-Green:dark'
  }

  $env.MCFLY_LIGHT = $isLightMode
}


