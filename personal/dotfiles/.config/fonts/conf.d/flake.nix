{
  inputs = {
    broot-icons-ttf = {
      url = "https://github.com/Canop/broot/raw/main/resources/icons/vscode/vscode.ttf";
      flake = false;
    };
  };
  outputs = { ... }@inputs: {
    nixosModules.default = { pkgs, ... }: let 
      brootIcons = pkgs.stdenv.mkDerivation {
        name = "broot-icons";
        src = inputs.broot-icons-ttf;
        dontUnpack = true;
        installPhase = ''
          install -Dm644 -t $out/share/fonts/truetype/ $src
        '';
      };
      fontList = [
          brootIcons
          # too big: pkgs.nerdfonts

          # See: https://dribbble.com/stories/2021/04/26/web-design-data-fonts
          # See: https://jichu4n.com/posts/the-most-popular-fonts-on-the-web-a-study/
          # "Times New Roman, Arial, and Courier New" replacement
          pkgs.liberation_ttf
          # "Arial Narrow" replacement
          pkgs.liberation-sans-narrow
          pkgs.helvetica-neue-lt-std
          pkgs.roboto
          pkgs.open-sans
          # Georgia replacement
          pkgs.gelasio
          pkgs.font-awesome
          pkgs.vistafonts

          pkgs.inter
          pkgs.noto-fonts
          pkgs.noto-fonts-emoji
          pkgs.twemoji-color-font
          pkgs.meslo-lgs-nf
          pkgs.cascadia-code
          pkgs.jetbrains-mono
        ];
    in {
      fonts = {
        packages = fontList;
      } // (if pkgs.stdenv.isDarwin then {
      } else {
        fontDir.enable = true;

        enableDefaultPackages = true;

        fontconfig = {
          enable = true;

          localConf = builtins.readFile ./default-font.conf;
          defaultFonts = {
            sansSerif = ["Inter" "Noto Sans"]; 
            serif = [ "Noto Serif"];
            monospace = ["JetBrains Mono" "Noto Sans Mono"];
            emoji = [ "Twitter Color Emoji" ];
          };
        };
      });
    };
  };
}