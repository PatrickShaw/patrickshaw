#!/usr/bin/env bash
killall .wofi-wrapped || wofi --prompt 'Search' --matching multi-contains --no-actions --show drun --insensitive --allow-images --allow-markup --style $HOME/.config/wofi/styles.css