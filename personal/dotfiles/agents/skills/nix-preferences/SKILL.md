---
name: nix-preferences
description: Patrick's preferences for Nix, NixOS, nix-darwin and home-manager config. Load before writing, reviewing or advising on Nix config, especially his machine config in ~/me.
---

# Nix preferences

- **Home-manager first**: If something can be a home-manager module, make it one. It works the same on NixOS, nix-darwin and standalone home-manager, and keeps things per-user. Only use NixOS or nix-darwin modules for genuinely system-level things (boot, networking, system services, sudo).
- **Keep non-Nix files out of Nix**: Shell scripts, rc files, JSON/YAML/TOML, Lua etc stay as real files in the dotfiles. Link them with `config.lib.file.mkOutOfStoreSymlink` rather than inlining them as Nix strings. They keep their own tooling (syntax highlighting, linters, formatters) and edits land straight back in the repo without a rebuild. Tiny bits of glue are fine inline.
- **Impermanence**: Hosts using impermanence keep state under `/persist`. Anything else is wiped on boot, so new stateful services need their paths persisted.
