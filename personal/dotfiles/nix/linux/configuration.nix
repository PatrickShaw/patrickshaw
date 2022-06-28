{ config, pkgs, lib, ... }:
let
  stable = import ./stable-pkgs.nix {};

  unstable-pkgs = import ./unstable-pkgs.nix {};
  default-pkgs = unstable-pkgs;

  shared-configuration = import ../shared/configuration.nix {
    pkgs = default-pkgs;
  };

  sharedAliases = import ../shared/program-aliases.nix {};
in
{
  imports = [
      shared-configuration
  ];

  virtualisation.docker.enable = true;
  environment.systemPackages = import ./apps.nix { pkgs = default-pkgs; };

  nixpkgs.config.packageOverrides = {
      edk2 = stable.edk2;
  };


  programs = {
    git = {
      enable = true;
      lfs.enable = true;
    };
    neovim = {
      enable = true;
      plugins = with pkgs; [
        vimPlugins.coc-nvim
        vimPlugins.coc-css
        vimPlugins.coc-yaml
        vimPlugins.coc-python
        vimPlugins.coc-git
        vimPlugins.coc-rust-analyzer
        vimPlugins.coc-tsserver
        vimPlugins.vim-nix
      ];
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
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  services.chrony.enable = true;
  services.timesyncd.enable = false;
  
  networking.timeServers =  [ "0.pool.ntp.org" "1.pool.ntp.org" "2.pool.ntp.org" "3.pool.ntp.org" "4.pool.ntp.org" "time.cloudflare.com" ]; 


  systemd.services.libvirtd-config.script = lib.mkAfter ''
    rm /var/lib/libvirt/qemu/networks/autostart/default.xml
  '';
  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.kernelParams = ["iommu=pt" "intel_iommu=on" "rd.driver.pre=vfio_pci" "vfio-pci.ids=10de:1c03,10de:10f1" "pcie_acs_override=downstream,multifunction"];
  boot.kernelModules = ["kvm_intel" "vfio_virqfd" "vfio_pci" "vfio_iommu_type1" "vfio" ];
  boot.blacklistedKernelModules = [ "nvidia" "nouveau" ];

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
        fonts = import ../shared/font-pkgs.nix { pkgs = default-pkgs; } ++ pkgs."jetbrains-mono";
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
