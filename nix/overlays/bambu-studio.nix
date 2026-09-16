_: _final: prev: let
  pname = "bambu-studio";
  version = "02.08.02.60";

  src = prev.fetchurl {
    url = "https://github.com/bambulab/BambuStudio/releases/download/v${version}/BambuStudio_ubuntu24.04-v${version}-20260814171356.AppImage";
    hash = "sha256-t40lJ6IO6fvPcO6CE4w7PKcHqpxmJYgWKdspYnJSrMM=";
  };

  appimageContents = prev.appimageTools.extract {
    inherit pname version src;
  };
in {
  bambu-studio = prev.appimageTools.wrapType2 {
    inherit pname version src;

    extraInstallPhase = ''
      mkdir -p $out/share/applications $out/share/icons/hicolor/128x128/apps
      if [ -f ${appimageContents}/BambuStudio.desktop ]; then
        cp ${appimageContents}/BambuStudio.desktop $out/share/applications/bambu-studio.desktop
      elif [ -f ${appimageContents}/bambu-studio.desktop ]; then
        cp ${appimageContents}/bambu-studio.desktop $out/share/applications/bambu-studio.desktop
      fi

      if [ -f ${appimageContents}/BambuStudio.png ]; then
        cp ${appimageContents}/BambuStudio.png $out/share/icons/hicolor/128x128/apps/bambu-studio.png
      elif [ -f ${appimageContents}/bambu-studio.png ]; then
        cp ${appimageContents}/bambu-studio.png $out/share/icons/hicolor/128x128/apps/bambu-studio.png
      fi

      if [ -f $out/share/applications/bambu-studio.desktop ]; then
        substituteInPlace $out/share/applications/bambu-studio.desktop \
          --replace-quiet "Exec=AppRun" "Exec=bambu-studio" \
          --replace-quiet "Icon=BambuStudio" "Icon=bambu-studio"
      fi
    '';

    meta = with prev.lib; {
      description = "Bambu Studio, an open-source cutting-edge 3D printing slicer software";
      homepage = "https://github.com/bambulab/BambuStudio";
      license = licenses.agpl3Plus;
      platforms = ["x86_64-linux"];
      mainProgram = "bambu-studio";
    };
  };
}
