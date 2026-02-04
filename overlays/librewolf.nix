_: final: prev: {
  librewolf-bin-unwrapped = prev.librewolf-bin-unwrapped.overrideAttrs (old: rec {
    pname = "librewolf-bin-unwrapped";
    inherit (prev.librewolf) version;

    src = prev.fetchurl {
      url = "https://codeberg.org/api/packages/librewolf/generic/librewolf/${version}/librewolf-${version}-linux-x86_64-package.tar.xz";
      hash = "sha256-SPGUDTwdEi9ztH9MiFxtiY+xn3258znyu6yw5a9J/YE=";
    };

    # The .tar.xz from Codeberg contains the exploded browser directory.
    unpackPhase = ''
      mkdir -p $out/lib/librewolf-bin-${version}
      tar -xJf $src -C $out/lib/librewolf-bin-${version} --strip-components=1
    '';

    installPhase = ''
      mkdir -p $out/bin
      ln -s $out/lib/librewolf-bin-${version}/librewolf $out/bin/librewolf

      # The wrapper expects a distribution directory with policies
      mkdir -p $out/lib/librewolf-bin-${version}/distribution
      echo '{"policies": {}}' > $out/lib/librewolf-bin-${version}/distribution/policies.json
      echo '{"policies": {}}' > $out/lib/librewolf-bin-${version}/distribution/extra-policies.json

      # Copy icons and desktop files from the unpacked directory to standard locations
      if [ -d $out/lib/librewolf-bin-${version}/browser/chrome/icons/default ]; then
        mkdir -p $out/share/icons/hicolor/128x128/apps
        cp $out/lib/librewolf-bin-${version}/browser/chrome/icons/default/default128.png $out/share/icons/hicolor/128x128/apps/librewolf.png
      fi

      if [ -f $out/lib/librewolf-bin-${version}/librewolf.desktop ]; then
        mkdir -p $out/share/applications
        cp $out/lib/librewolf-bin-${version}/librewolf.desktop $out/share/applications/librewolf.desktop
        sed -i "s|Exec=librewolf|Exec=$out/bin/librewolf|g" $out/share/applications/librewolf.desktop
      fi
    '';

    meta =
      old.meta
      // {
        knownVulnerabilities = [];
      };
  });

  librewolf-bin = prev.librewolf-bin.overrideAttrs (old: {
    inherit (final.librewolf-bin-unwrapped) version;
    meta =
      old.meta
      // {
        knownVulnerabilities = [];
      };
  });
}
