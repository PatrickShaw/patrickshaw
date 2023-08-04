{
  outputs = { ... }: {
    nixosModules.default = { pkgs, ... }: {
      environment.systemPackages = [
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

      ];
      fonts = {
        fontconfig = {
          localConf = builtins.readFile ./default-font.conf;
        };
      };
    };
  };
}