#!/usr/bin/env nu
let light = true;

MCFLY_LIGHT=$light
if light {
  gsettings set org.gnome.desktop.interface color-scheme prefer-light
} else {
  gsettings set org.gnome.desktop.interface color-scheme prefer-dark
}

