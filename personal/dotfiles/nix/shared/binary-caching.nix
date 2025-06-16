{
  nix.settings = {
    extra-substituters = [
      "https://cache.nixos.org?priority=1"

      "https://nix-gaming.cachix.org"

      # See: https://wiki.hyprland.org/Nix/Cachix/
      # "https://hyprland.cachix.org"

      # See: https://github.com/nix-community/nixpkgs-wayland#binary-cache
      # "https://nixpkgs-wayland.cachix.org"

      "https://nix-community.cachix.org"

      # "https://helix.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      # "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      # "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      # "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
    ];
  };
}
