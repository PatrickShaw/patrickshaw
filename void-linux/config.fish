source (status dirname)/../shared/config.fish
alias code="code-oss"

fish_add_path $HOME/.cargo/bin

if status is-login
    sway --my-next-gpu-wont-be-nvidia &
    pipewire &
    pipewire-pulse &
    pipewire-media-session &
end