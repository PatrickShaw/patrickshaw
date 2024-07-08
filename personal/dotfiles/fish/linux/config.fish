source (status dirname)/../shared/config.fish
# alias code="code-oss"

# All handled by Nix
#fish_add_path $HOME/.cargo/bin
#fish_add_path $HOME/.yarn/bin
if status is-interactive
    # See: https://github.com/keybase/keybase-issues/issues/2798
    set -x GPG_TTY $(tty)
end

if status is-login; and not set -q SSH_TTY
    # Was only required when running Void Linux/non-systemd
    #if test -z "$XDG_RUNTIME_DIR"
    #  set runtime_dir "/tmp/"(id -u)"-xdg-runtime-dir"
    #  mkdir "$runtime_dir"
    #  chmod 0700 "$runtime_dir"
    #  set -gx XDG_RUNTIME_DIR $runtime_dir       
    #end

    #dbus-run-session sway --unsupported-gpu
    #dbus-run-session river
    # So, it turns out that WLR_RENDERER does NOT support vulkan and for whatever reason, the WLR_RENDERER=vulkan flags were previously being ignored
    # See: https://github.com/hyprwm/Hyprland/issues/1396
    # See: https://www.reddit.com/r/swaywm/comments/17j1icw/about_wlr_renderervulkan_screen_flickering/
    WLR_RENDERER=gles2 nice -n -5 Hyprland

    # All handled by Nix
    #dbus-launch pipewire &
    #dbus-launch pipewire-pulse &
    #dbus-launch pipewire-media-session &
end
