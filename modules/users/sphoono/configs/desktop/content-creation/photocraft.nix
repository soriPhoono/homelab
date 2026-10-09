{
  # PhotoCraft, packaged from the upstream AppImage. The AppImage ships its own
  # desktop entry, icons and mime types, which are installed alongside the
  # wrapper. State lives in the app's XDG directories and is not managed
  # declaratively.
  den.aspects.sphoono.content-creation.homeManager =
    { pkgs, ... }:
    let
      pname = "photocraft";
      version = "0.5.0";

      src = pkgs.fetchurl {
        url = "https://github.com/storytold/${pname}/releases/download/v${version}/${pname}-${version}-linux-x86_64.AppImage";
        hash = "sha256-9U2GOAcFO738/6DWJO9+SdP9QTEMe7Ht5IU29pkp0i8=";
      };

      extracted = pkgs.appimageTools.extract { inherit pname version src; };

      wrapped = pkgs.appimageTools.wrapType2 {
        inherit pname version src;
        extraInstallCommands = ''
          mkdir -p $out/share
          for d in applications icons metainfo mime; do
            if [ -d ${extracted}/usr/share/$d ]; then
              cp -r ${extracted}/usr/share/$d $out/share/$d
            fi
          done
        '';
      };
    in
    {
      home.packages = [ wrapped ];
    };
}
