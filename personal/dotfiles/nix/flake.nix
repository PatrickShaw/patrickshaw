{
  inputs = {
    nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";
    hyprland.url = "github:hyprwm/Hyprland";
    eww.url = "github:elkowar/eww";
  };
  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org/"

      # See: https://wiki.hyprland.org/Nix/Cachix/
      "https://hyprland.cachix.org"

      # See: https://github.com/nix-community/nixpkgs-wayland#binary-cache
      "https://nixpkgs-wayland.cachix.org"

      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
    ];
  };
  outputs = { self, ... }@inputs: {
    nixosModules.default = { config, pkgs, lib, options, ... }:
      let
        wayland-pkgs = inputs.nixpkgs-wayland.packages.${pkgs.system};
        shared-configuration = import ./shared/configuration.nix { inherit pkgs; };
        shared-aliases = import ./shared/program-aliases.nix { };
      in 
      {
        imports = [
            shared-configuration
            inputs.hyprland.nixosModules.default
        ];
        
        # See: https://github.com/NixOS/nixpkgs/issues/16327
        services.gnome.at-spi2-core.enable = true;
        
        programs.hyprland = {
          enable = true;

          # default options, you don't need to set them
          package = inputs.hyprland.packages.${pkgs.system}.default;

          xwayland = {
            enable = true;
            hidpi = true;
          };

          nvidiaPatches = false;
        };

        # See: https://wiki.archlinux.org/title/PipeWire#xdg-desktop-portal-wlr
        # See: https://nixos.wiki/wiki/Sway#Using_NixOS
        xdg.portal = {
          enable = true;
          wlr.enable = true;
          # gtk portal needed to make gtk apps happy
          extraPortals = [
            pkgs.xdg-desktop-portal-gtk
            # Saw this declared in: https://discourse.nixos.org/t/xdg-desktop-portal-not-working-on-wayland-while-kde-is-installed/20919
            #wayland-pkgs.xdg-desktop-portal-wlr
          ];
        };

        nixpkgs.config.allowUnfree = true;

        virtualisation.docker.enable = false;
        environment.systemPackages = [
          wayland-pkgs.wl-clipboard
          wayland-pkgs.swww
          wayland-pkgs.wofi
          wayland-pkgs.grim
          wayland-pkgs.imv
          wayland-pkgs.sway-unwrapped
          inputs.eww.packages.${pkgs.system}.eww-wayland
        ] ++ import ./linux/apps.nix { inherit pkgs; };

        i18n.defaultLocale = "en_AU.UTF-8";

        environment.etc = {
          # This is to make systemd past boots of journals actually log out when listed
          # See https://www.reddit.com/r/NixOS/comments/kgziex/journald_not_keeping_past_boot_logs/
          machine-id.text = "152099709ccc4cc79fec46efcb18d2a1";
          "pipewire/pipewire.conf.d/10-personal-settings".text = ''
default.clock.rate = 96000;
default.clock.quantum = 24;
default.clock.min-quantum = 24;
          '';
        };

        programs = {
          git = {
            enable = true;
            lfs.enable = true;
          };
          neovim = {
            enable = true;
            /* plugins = with pkgs; [
                vimPlugins.coc-nvim
                vimPlugins.coc-css
                vimPlugins.coc-yaml
                vimPlugins.coc-python
                vimPlugins.coc-git
                vimPlugins.coc-rust-analyzer
                vimPlugins.coc-tsserver
                vimPlugins.vim-nix
              ];
            */
          };
          zsh = {
            enable = true;
            shellAliases = shared-aliases;
            # We do this ourselves
            enableCompletion = false;
          };
          fish = {
            enable = true;
            shellAliases = shared-aliases;
          };
        };

        systemd.tmpfiles.rules = [ "f /dev/shm/looking-glass 0660 1000 kvm -" ];

        # Bootloader/EFI
        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;

        services.chrony.enable = true;
        services.timesyncd.enable = false;

        networking.timeServers = options.networking.timeServers.default
          ++ [ "time.cloudflare.com" ];

        systemd.services.libvirtd-config.script = lib.mkAfter ''
          #rm /var/lib/libvirt/qemu/networks/autostart/default.xml
        '';

        # See: https://nixos.org/manual/nixos/stable/release-notes.html#sec-release-22.05-notable-changes
        # It auto enables Wayland flags for Electron apps
        environment.sessionVariables.NIXOS_OZONE_WL = "1";

        environment.sessionVariables.LIBVIRT_DEFAULT_URI = [ "qemu:///system" ];

        hardware.opengl.enable = true;

        # See: https://nixos.wiki/wiki/PipeWire
        security.rtkit.enable = true;

        services.pipewire = {
          enable = true;
          alsa.enable = false;
          alsa.support32Bit = false;
          #alsa.enable = true;
          #alsa.support32Bit = true;
          pulse.enable = true;
          jack.enable = true;
          wireplumber.enable = true;

          # Copied from: https://forum.level1techs.com/t/nixos-vfio-pcie-passthrough/130916/4
          socketActivation = true;
        };

        programs.dconf.enable = true;

        services.gvfs.enable = true;

        services.openssh.enable = true;

        # Fonts
        fonts = {
            enableDefaultFonts = true;
            fonts = import ./shared/font-pkgs.nix { inherit pkgs; };
            fontconfig = {
              defaultFonts = {
                  #systemUI = [ "Inter" "Noto Sans" ];
                  #sans = ["Inter" "Noto Sans"]; 
                  sansSerif = ["Inter" "Noto Sans"]; 
                  serif = [ "Noto Serif"];
                  monospace = ["JetBrains Mono" "Noto Sans Mono"];
                  emoji = [ "Twitter Color Emoji" ];
              };
          };
        };
      };

  };
}