{
  inputs = {
    nixpkgs = { url = "github:nixos/nixpkgs/nixos-unstable"; };

    nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";
    nixpkgs-wayland.inputs.nixpkgs.follows = "nixpkgs";

    hyprland.url = "github:hyprwm/Hyprland";
    hyprland.inputs.nixpkgs.follows = "nixpkgs";
    
    rust-overlay.url = "github:oxalica/rust-overlay";

    eww.url = "github:elkowar/eww";
    eww.inputs.nixpkgs.follows = "nixpkgs";
    eww.inputs.rust-overlay.follows = "rust-overlay";

    # helix.url = "github:helix-editor/helix";
    # helix.inputs.nixpkgs.follows = "nixpkgs";
    # helix.inputs.rust-overlay.follows = "rust-overlay";

    nix-direnv.url = "github:nix-community/nix-direnv";
    nix-direnv.inputs.nixpkgs.follows = "nixpkgs";

  };
  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org/"

      # See: https://github.com/nix-community/nixpkgs-wayland#binary-cache
      "https://nixpkgs-wayland.cachix.org"

      "https://nix-community.cachix.org"

      # See: https://wiki.hyprland.org/Nix/Cachix/
      "https://hyprland.cachix.org"
    ];
    extra-trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
    ];
  };
  outputs = { self, ... }@inputs: 
  {
    nixosModules = {
      opengl = { pkgs, ... }: {
        hardware.opengl = {
          enable = true;
          driSupport = true;
          driSupport32Bit = true;
          extraPackages = [
            # See https://nixos.wiki/wiki/Accelerated_Video_Playback
            pkgs.vaapiVdpau
            pkgs.libvdpau-va-gl
          ];
        };
      };
      intel-integrated-graphics = { pkgs, ... }: {
        imports = [self.nixosModules.opengl];
        hardware.opengl = {
          extraPackages = [
            # See https://nixos.wiki/wiki/Accelerated_Video_Playback
            pkgs.intel-media-driver
          ];
      };
        environment.sessionVariables = {
          LIBVA_DRIVER_NAME="iHD";
          # What I currently use as my wlroots backend ATM
          WLR_RENDERER = "vulkan";
        };
      };
      nvidia = { config, pkgs, ... }: {
        imports = [self.nixosModules.opengl];
        services.xserver.videoDrivers = [ "nvidia" ];
        hardware.nvidia = {
          package = config.boot.kernelPackages.nvidiaPackages.stable;
        };

        environment.sessionVariables = {
          # What I currently use as my wlroots backend ATM
          WLR_RENDERER = "vulkan";
        };

        hardware.opengl = {
          extraPackages = [
            # See: https://nixos.wiki/wiki/Accelerated_Video_Playback
            pkgs.nvidia-vaapi-driver
          ];
        };
      };
      nvidia-a1000 = { ... }: {
        imports = [self.nixosModules.nvidia];
        hardware.nvidia = {
          # https://nixos.wiki/wiki/Nvidia mentions it'll fix sleep
          powerManagement.enable = true;
          powerManagement.finegrained = false;
          modesetting.enable = false;

          open = false;

          prime = {
            offload = {
              enable = true;
              enableOffloadCmd = true;
            };
          };
        };
        environment.sessionVariables = {
          # WLR_NO_HARDWARE_CURSORS="1";

          # Update: Realisitically, not worth offloading everything
          # https://nixos.wiki/wiki/Nvidia
          # __NV_PRIME_RENDER_OFFLOAD="1";
          # __NV_PRIME_RENDER_OFFLOAD_PROVIDER="NVIDIA-G0";
          # __VK_LAYER_NV_optimus="NVIDIA_only";
        };
      };
      nvidia-gtx1060 = { ... }: {
        boot.kernelModules = [
          "nvidia"
          "nvidia_modeset"
          "nvidia_uvm"
          "nvidia_drm"
        ];
        imports = [self.nixosModules.nvidia];
        hardware.nvidia = {
          open = false; 
          # See KMS doco in Arch. Meant to enable newer rendering methods, etc
          modesetting.enable = true;
        };
        environment.sessionVariables = {
          # Won't render hardware cursors
          WLR_NO_HARDWARE_CURSORS="1";
          
          # See: https://wiki.hyprland.org/Configuring/Environment-variables/
          # See: https://github.com/hyprwm/Hyprland/issues/1878
          GBM_BACKEND="nvidia";
          __GLX_VENDOR_LIBRARY_NAME="nvidia";
          LIBVA_DRIVER_NAME="nvidia";
        };
      };
      text-to-speech = { ... }: {
        services.tts.servers = {
          english = {
            port = 5300;
            model = "tts_models/en/ljspeech/tacotron2-DDC";
            enable = true;
          };
        };
      };
      vfio = { ... }: {
        systemd.tmpfiles.rules = [ "f /dev/shm/looking-glass 0660 1000 kvm -" ];
        environment.sessionVariables = {
        LIBVIRT_DEFAULT_URI = [ "qemu:///system" ];
      };
    };
      direnv = { pkgs, ... }: {
        nixpkgs.overlays = [
          inputs.nix-direnv.overlay
          (final: super: {
            nix-direnv = super.nix-direnv.overrideAttrs (old: old // {
              enableFlakes = true;
            });
          })
        ];

        environment.systemPackages = [
          # (inputs.nix-direnv.packages.${pkgs.system}.default.override {
          #   enableFlakes = true;
          # })
          pkgs.direnv
        ];

        environment.pathsToLink = [
          "/share/nix-direnv"
        ];
      };
      core = { pkgs, lib, options, ...}: let
        wayland-pkgs = inputs.nixpkgs-wayland.packages.${pkgs.system};
        shared-configuration = import ./shared/configuration.nix { inherit pkgs; };
        shared-aliases = import ./shared/program-aliases.nix { };

        # See https://nixos.wiki/wiki/Sway
        configure-gtk = pkgs.writeTextFile {
          name = "configure-gtk";
          destination = "/bin/configure-gtk";
          executable = true;
          text = let
            schema = pkgs.gsettings-desktop-schemas;
            datadir = "${schema}/share/gsettings-schemas/${schema.name}";
          in ''
            export XDG_DATA_DIRS=${datadir}:$XDG_DATA_DIRS
            gnome_schema=org.gnome.desktop.interface

            gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
            gsettings set org.gnome.desktop.interface gtk-theme 'Orchis-Green'
            # Add for good measure. See: https://wiki.hyprland.org/FAQ/#gtk-settings-no-work--whatever
            gsettings set org.gnome.desktop.interface cursor-theme 'phinger-cursors'
            gsettings set org.gnome.desktop.interface cursor-blink false
          '';
        };
      in {
        imports = [
            shared-configuration
            inputs.hyprland.nixosModules.default
            self.nixosModules.direnv
            self.nixosModules.text-to-speech
        ];

        # For whatever reason, systemd's oom is disabled anyway so we enable our own
        systemd.oomd.enable = false;
        services.earlyoom.enable = true;


        programs.hyprland.package = inputs.hyprland.packages.${pkgs.system}.default;
        programs.hyprland.enable = true;

        nixpkgs.overlays = [
          inputs.hyprland.overlays.default
        ];

        programs.captive-browser.enable = true;
        programs.captive-browser.interface = "wlan0";

        # See: https://superuser.com/questions/904331/how-does-btrfs-scrub-work-and-what-does-it-do
        # Should probably go in an FS module
        services.btrfs.autoScrub.enable = true;
        
        # Makes sharing with Windows storage devices easier
        boot.supportedFilesystems = [ "ntfs" ];

        hardware.enableRedistributableFirmware = true;

        nix.gc = {
          automatic = true;
          dates = "weekly";
          persistent = true;
          options = "--delete-older-than 30d";
        };

        # See: https://github.com/NixOS/nixpkgs/issues/16327
        # Also: https://github.com/NixOS/nixpkgs/issues/197188#issuecomment-1320990068
        services.gnome.at-spi2-core.enable = true;
        services.xserver = {
          enable = false;
          
          libinput = {
            enable = true;

            mouse = {
              accelProfile = "flat";
            };

            touchpad = {
              accelProfile = "adaptive";
            };
          };
        };

        nixpkgs.config.allowUnfree = true;

                # See: https://wiki.archlinux.org/title/PipeWire#xdg-desktop-portal-wlr
        # See: https://nixos.wiki/wiki/Sway#Using_NixOS
        # As per https://github.com/hyprwm/Hyprland/blob/f23455e592bca14e0abd9249de467cc71cd2850e/nix/module.nix#L88, this is turned on by Hyprland itself
        # ^ Update: But for file choosers xdg-desktop-portal-gtk is needed
        xdg.portal = {
           xdgOpenUsePortal = true;
           enable = true;
          wlr.enable = false;
           extraPortals = [
              # 2023-04-26: Commented out because of the following
              # See: https://wiki.hyprland.org/Useful-Utilities/Hyprland-desktop-portal/
              # "It’s recommended to uninstall any other portal implementations to avoid conflicts with the -hyprland or -wlr ones. -kde and -gnome are known to cause issues."
              # 2023-07-03: Uncommented because
              # a) It stops vite working - More or less confirmed this is the case
              # b) The Hyprland doco actually says "Only -gtk will work with -hyprland or -wlr on Hyprland.". See: https://wiki.hyprland.org/Useful-Utilities/Hyprland-desktop-portal/#debugging
              # c) I remember I orginally uncommented because of VSCode kept crashing but that's since been fixed by changing the title bar from native to custom
              pkgs.xdg-desktop-portal-gtk
              # Saw this declared in: https://discourse.nixos.org/t/xdg-desktop-portal-not-working-on-wayland-while-kde-is-installed/20919
              #wayland-pkgs.xdg-desktop-portal-wlr
           ];
            configPackages = [
              pkgs.xdg-desktop-portal-hyprland
              pkgs.xdg-desktop-portal-gtk
            ];
        };

        environment.systemPackages = [
          configure-gtk

          wayland-pkgs.wl-clipboard
          wayland-pkgs.swww
          wayland-pkgs.wofi
          wayland-pkgs.grim
          wayland-pkgs.slurp
          wayland-pkgs.imv
          #wayland-pkgs.sway-unwrapped
          wayland-pkgs.mako

          inputs.eww.packages.${pkgs.system}.eww-wayland

          # inputs.helix.packages.${pkgs.system}.default

          pkgs.libimobiledevice
          pkgs.ifuse 

          pkgs.nix-direnv

          pkgs.libinput-gestures
        ] ++ import ./linux/apps.nix { inherit pkgs; };

        programs = {
          git = {
            enable = true;
            lfs.enable = true;
          };
          neovim = {
            enable = true;
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
        i18n.defaultLocale = "en_AU.UTF-8";

        # Bootloader/EFI
        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;
        boot.loader.timeout = lib.mkDefault 2;


        services.chrony.enable = true;
        services.timesyncd.enable = false;

        # For automounting disks
        services.udisks2.enable = true;

        environment.etc = {
          # This is to make systemd past boots of journals actually log out when listed
          # See https://www.reddit.com/r/NixOS/comments/kgziex/journald_not_keeping_past_boot_logs/
          machine-id.text = "152099709ccc4cc79fec46efcb18d2a1";

          # Note: Writing systemd units here won't work. Use systemd.user.*
        };

        # Udev rules - Includes some for Sony DS4
        hardware.steam-hardware.enable = true;
        services.udev.packages = [
          pkgs.android-udev-rules
        ];
        
        networking.timeServers = options.networking.timeServers.default
          ++ [ "time.cloudflare.com" ];

        systemd.services.libvirtd-config.script = lib.mkAfter ''
          #rm /var/lib/libvirt/qemu/networks/autostart/default.xml
        '';
        environment.sessionVariables = {
          # See: https://wiki.archlinux.org/title/Cursor_themes
          XCURSOR_THEME = "phinger-cursors";
          XCURSOR_SIZE = "24";

          # Enable if you want to unbind and rebind secondary GPU cards easily 
          # Hyprland attaches processes to other GPUs too
          #WLR_DRM_DEVICES="/dev/dri/card0";

          # See: https://nixos.org/manual/nixos/stable/release-notes.html#sec-release-22.05-notable-changes
          # It auto enables Wayland flags for Electron apps
          NIXOS_OZONE_WL = "1";


          # For whatever reason nautilus won't respect my theme without this
          # GTK_THEME = "Orchis-Green:dark";

          MOZ_ENABLE_WAYLAND = "1";

          # See https://discourse.nixos.org/t/how-to-reload-mime-database-after-update-gtk-application-crashes-on-icon-load/14152/3
          # Appears to make final pickers work properly (although chooses one I wouldn't expect)
          #QT_QPA_PLATFORMTHEME="xdgdesktopportal";

          # See https://github.com/cantino/mcfly#fuzzy-searching
          MCFLY_FUZZY="2";
          MCFLY_HISTORY_LIMIT="40000";
          MCFLY_PROMPT="❯";
          MCFLY_RESULTS="15";
        };
        hardware.opengl.enable = true;

        # See: https://nixos.wiki/wiki/PipeWire
        security.rtkit.enable = true;
        
        services.usbmuxd = {
          enable = true;
          # usbmuxd2 doesn't seem to be maintained
          # package = pkgs.usbmuxd2;
        };

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
        
        # Should start a service based on https://github.com/NixOS/nixpkgs/blob/27bd67e55fe09f9d68c77ff151c3e44c4f81f7de/nixos/modules/programs/nm-applet.nix#L26
        programs.nm-applet.enable = true;
      };
      default = { config, pkgs, lib, options, ... }: {
        imports = [
            self.nixosModules.core
        ];

        virtualisation.docker.enable = true;
        virtualisation.docker.storageDriver = "btrfs";
      };
    };
  };
}
