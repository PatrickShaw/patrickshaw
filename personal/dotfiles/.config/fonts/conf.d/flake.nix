{
  inputs = {
    fontConf.url = "./default-font.conf";
    fontConf.flake = false;
  };
  outputs = { fontConf }: {
    nixosModules.default = { ... }: {
      fonts = {
        fontconfig = {
          localConf = fontConf;
        };
      };
    }
  };
}