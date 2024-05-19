{
  outputs = { self, ... }@inputs: {
    overlays.default = final:
      let 
        wrapWithNice = { pkg, niceValue }:
          final.stdenv.mkDerivation rec {
            name = "${pkg.name}-nice";
            buildInputs = [ final.makeWrapper ];

            # Ensure we inherit the original package's system dependencies
            passthru = pkg.passthru;


            # variable $src or $srcs should point to the source
            dontUnpack = true;
            # unpackPhase = false;
            # src = ./.;

            # Build phase is not necessary because we're only wrapping an existing package
            dontBuild = true;

            # Disable various phases to speed up the process
            doCheck = false;
            doInstallCheck = false;

            # Install phase
            installPhase = ''
              mkdir -p $out/bin

              # Wrap each executable in the package's bin directory
              for prog in ${pkg}/bin/*; do
                if [ -x $prog ]; then
                  exeName=$(basename $prog)
                  printf "#!${final.bash}/bin/bash\nexec ${final.uutils-coreutils}/bin/uutils-nice -n ${toString niceValue} $prog" > $out/bin/$exeName
                  chmod +x $out/bin/$exeName
                fi
              done
            '';

            # Inherit meta-information from the original package
            meta = pkg.meta;
          };
      in 
      prev: {
        firefox = wrapWithNice { pkg = prev.firefox; niceValue = -1; };
        google-chrome = wrapWithNice {
          pkg = prev.google-chrome;
          niceValue = -1;
        };
      };
  };
}