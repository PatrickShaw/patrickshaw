source (status dirname)/../shared/config.fish
alias code="code-oss"

if status is-login
    sway --my-next-gpu-wont-be-nvidia &
    pipewire &
    pipewire-pulse &
    pipewire-media-session &
end