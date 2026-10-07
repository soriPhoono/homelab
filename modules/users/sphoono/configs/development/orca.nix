_: {
  # Orca ADE, packaged from the upstream AppImage. State lives in
  # ~/.config/orca and is deliberately not managed declaratively. Wayland is
  # enabled session-wide by NIXOS_OZONE_WL in the desktop aspect.
  den.aspects.sphoono.development.orca.homeManager =
    { pkgs, ... }:
    let
      pname = "orca";
      version = "1.4.222";

      src = pkgs.fetchurl {
        url = "https://github.com/stablyai/orca/releases/download/v${version}/orca-linux.AppImage";
        hash = "sha256-P/vCcym7Qn1t3LfkCM98LVyIhgLUsPS5is/XTdW6XrU=";
      };

      extracted = pkgs.appimageTools.extractType2 { inherit pname version src; };

      wrapped = pkgs.appimageTools.wrapType2 {
        inherit pname version src;
        # Upstream names the binary orca-ide so GNOME Orca keeps the plain
        # name; both are exposed here.
        extraInstallCommands = ''
          ln -s $out/bin/${pname} $out/bin/orca-ide

          mkdir -p $out/share
          if [ -d ${extracted}/usr/share/icons ]; then
            cp -r ${extracted}/usr/share/icons $out/share/icons
          fi

          mkdir -p $out/share/applications
          cat > $out/share/applications/orca-ide.desktop <<DESKTOP
          [Desktop Entry]
          Type=Application
          Name=Orca
          Comment=Agent Development Environment
          Exec=$out/bin/orca-ide %U
          Icon=orca-ide
          Categories=Development;IDE;
          MimeType=x-scheme-handler/orca;
          StartupWMClass=orca
          Terminal=false
          DESKTOP
        '';
      };
    in
    {
      home.packages = [ wrapped ];
    };
}
