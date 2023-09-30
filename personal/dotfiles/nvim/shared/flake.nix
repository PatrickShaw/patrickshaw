{
  inputs = {
    utils.url = "github:numtide/flake-utils";
  };
  outputs = { utils }: utils.lib.eachDefaultSystem (system: {
    
  });
}