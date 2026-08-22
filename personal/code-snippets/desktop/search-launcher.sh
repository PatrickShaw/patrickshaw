#!/usr/bin/env bash
# Toggle the app launcher: kill it if already running, otherwise show it.
#
# Migrated from wofi. Most of the old flags are now defaults or live in the
# config file, so they're dropped rather than translated:
#   --show drun / --insensitive / --allow-images  -> fuzzel's default behaviour
#   --matching multi-contains                     -> match-mode in fuzzel.ini
#   --style ...styles.scss                        -> fuzzel.ini has no separate stylesheet
killall fuzzel || fuzzel --prompt 'Search '
