#!/usr/bin/env sh
rm -rf ./assets/icons/material/**
./download-material-icons.ts \
  https://fonts.gstatic.com/s/i/materialiconsround/volume_up/v14/24px.svg \
  https://fonts.gstatic.com/s/i/short-term/release/materialsymbolsrounded/volume_off/default/48px.svg
  https://fonts.gstatic.com/s/i/short-term/release/materialsymbolsrounded/volume_down/default/48px.svg
