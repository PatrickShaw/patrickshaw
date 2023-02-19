{ config, pkgs, lib, options, ... }:
let
  shared-configuration = import ../shared/configuration.nix {
    inherit pkgs;
  };

  sharedAliases = import ../shared/program-aliases.nix {};
in
{
  imports = [
      shared-configuration
  ];

  nixpkgs.config.allowUnfree = true;

  virtualisation.docker.enable = false;
  environment.systemPackages = import ./apps.nix { inherit pkgs; };

  i18n.defaultLocale = "en_AU.UTF-8";

  # This is to make systemd past boots of journals actually log out when listed
  # See https://www.reddit.com/r/NixOS/comments/kgziex/journald_not_keeping_past_boot_logs/
  environment.etc.machine-id.text = "152099709ccc4cc79fec46efcb18d2a1";

  programs = {
    git = {
      enable = true;
      lfs.enable = true;
    };
    neovim = {
      enable = true;
      /*plugins = with pkgs; [
        vimPlugins.coc-nvim
        vimPlugins.coc-css
        vimPlugins.coc-yaml
        vimPlugins.coc-python
        vimPlugins.coc-git
        vimPlugins.coc-rust-analyzer
        vimPlugins.coc-tsserver
        vimPlugins.vim-nix
      ];*/
    };
    zsh = {
      enable = true;
      shellAliases = sharedAliases;
      # We do this ourselves
      enableCompletion = false;
    };
    fish = {
      enable = true;
      shellAliases = sharedAliases;
    };
  };
  
  systemd.tmpfiles.rules = [
    "f /dev/shm/looking-glass 0660 1000 kvm -"
  ];

    # Bootloader/EFI
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.chrony.enable = true;
  services.timesyncd.enable = false;
  
  networking.timeServers =  options.networking.timeServers.default ++ [ "time.cloudflare.com" ]; 


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
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
   "media-session".enable = false;
   wireplumber.enable = true;

    # Copied from: https://forum.level1techs.com/t/nixos-vfio-pcie-passthrough/130916/4
    socketActivation = true;

    config.pipewire = {
      "context.properties" = {
        "default.clock.rate" = 48000;
      	"default.clock.quantum" = 512;
      };
    };
  };

  programs.dconf.enable = true;
  
  services.gvfs.enable = true;

  services.openssh.enable = true;

    # Fonts
    fonts = {
        enableDefaultFonts = true;
        fonts = import ../shared/font-pkgs.nix { inherit pkgs; };
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
}
