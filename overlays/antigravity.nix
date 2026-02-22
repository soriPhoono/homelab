_: final: prev: {
  antigravity = prev.stdenv.mkDerivation rec {
    pname = "antigravity";
    version = "1.18.4";
    buildId = "5780041996042240";
    fullVersion = "${version}-${buildId}";

    # To update, change the version, buildId, and sha256.
    src = prev.fetchurl {
      url = "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/${fullVersion}/linux-x64/Antigravity.tar.gz";
      sha256 = "f97d790d1fb74e8ccb9ddb6af301a2b60391aed22f633f1a2baf86862aa65826";
    };

    nativeBuildInputs = [
      prev.autoPatchelfHook
      prev.makeWrapper
    ];

    buildInputs = with prev; [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      cairo
      cups
      dbus
      expat
      gdk-pixbuf
      glib
      gtk3
      libdrm
      libuuid
      libxkbcommon
      mesa
      nspr
      nss
      pango
      systemd
      xorg.libX11
      xorg.libXcomposite
      xorg.libXcursor
      xorg.libXdamage
      xorg.libXext
      xorg.libXfixes
      xorg.libXi
      xorg.libXrandr
      xorg.libXrender
      xorg.libXScrnSaver
      xorg.libXtst
      xorg.libxcb
      xorg.libxshmfence
    ];

    installPhase = ''
      mkdir -p $out/bin $out/lib/antigravity
      cp -r * $out/lib/antigravity

      # The binary name inside the archive is assumed to be "Antigravity"
      if [ -f $out/lib/antigravity/Antigravity ]; then
        makeWrapper $out/lib/antigravity/Antigravity $out/bin/antigravity \
          --prefix LD_LIBRARY_PATH : ${prev.lib.makeLibraryPath buildInputs}
      elif [ -f $out/lib/antigravity/antigravity ]; then
        makeWrapper $out/lib/antigravity/antigravity $out/bin/antigravity \
          --prefix LD_LIBRARY_PATH : ${prev.lib.makeLibraryPath buildInputs}
      else
        echo "Error: Could not find Antigravity binary."
        ls -R $out/lib/antigravity
        exit 1
      fi

      # Symlink for code compatibility
      ln -s $out/bin/antigravity $out/bin/code

      # Attempt to install desktop file if it exists in the standard location for electron apps
      if [ -d $out/lib/antigravity/resources/app/resources/linux/code.desktop ]; then
         mkdir -p $out/share/applications
         install -D $out/lib/antigravity/resources/app/resources/linux/code.desktop $out/share/applications/antigravity.desktop
         sed -i 's|Exec=.*|Exec=antigravity|' $out/share/applications/antigravity.desktop
         sed -i 's|Icon=.*|Icon=antigravity|' $out/share/applications/antigravity.desktop
         sed -i 's|Name=.*|Name=Antigravity|' $out/share/applications/antigravity.desktop
      fi
    '';

    meta = with prev.lib; {
      description = "Antigravity Editor";
      homepage = "https://antigravity.google/";
      license = licenses.unfree;
      platforms = [ "x86_64-linux" ];
      mainProgram = "antigravity";
    };
  };
}
