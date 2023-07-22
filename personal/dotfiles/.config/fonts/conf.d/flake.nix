{
  outputs = { ... }: {
    nixosModules.default = { ... }: {
      fonts = {
        fontconfig = {
          localConf = builtins.readFile ./default-font.conf;
        };
      };
    };
  };
}