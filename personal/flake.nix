{
  description = "Monorepo environment";

  inputs = {
    utils.url = "github:numtide/flake-utils";
    alejandra.url = "github:serokell/nixfmt";
  };

  outputs = { self, utils, alejandra, }:
    utils.lib.eachDefaultSystem
    (system: { formatter = alejandra.packages.${system}.default; });
}
