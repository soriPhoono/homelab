{ lib, ... }: {
  den.aspects.core.hardware.hid.tablets.xp-pen = {
    nixos =
      { pkgs, config, ... }:
      {
        options.core.hardware.xpPen.tablets = lib.mkOption {
          type = lib.types.listOf (
            lib.types.enum [
              "artist-13.3-pro"
            ]
          );
          default = [ ];
          description = "XP-Pen tablet variants physically present on this host.";
        };

        config =
          let
            xp-pen-overlay = _final: prev: {
              xp-pen-13-3-pro = prev.stdenv.mkDerivation rec {
                pname = "xp-pen-driver";
                version = "4.0.15-260422";

                src = prev.fetchurl {
                  url = "https://www.xp-pen.com/download/file.html?id=4404&pid=430&ext=gz";
                  name = "xp-pen-driver-${version}.tar.gz";
                  sha256 = "19czwmbgqqvlna7k554dvbnl2kk87y724d736aakk7zajvx759r5";
                };

                nativeBuildInputs = [
                  prev.autoPatchelfHook
                  prev.qt5.wrapQtAppsHook
                ];

                buildInputs = [
                  prev.stdenv.cc.cc.lib
                  prev.libx11
                  prev.libxext
                  prev.libxi
                  prev.libxrandr
                  prev.libxrender
                  prev.libxtst
                  prev.libxcb
                  prev.libusb1
                  prev.libGL
                  prev.glib
                  prev.dbus
                  prev.fontconfig
                  prev.freetype
                  prev.zlib
                  prev.qt5.qtbase
                  prev.qt5.qtx11extras
                ];

                sourceRoot = ".";

                installPhase = ''
                        runHook preInstall

                        dir=$(ls -d XPPenLinux*)

                        mkdir -p $out/bin
                        mkdir -p $out/lib/udev/rules.d
                        mkdir -p $out/share/applications
                        mkdir -p $out/share/icons/hicolor/256x256/apps
                        mkdir -p $out/opt/xp-pen

                        # Copy all application files to /opt/xp-pen/
                        cp -r $dir/App/usr/lib/pentablet/* $out/opt/xp-pen/

                        # Remove bundled Qt libraries so autoPatchelf uses nixpkgs ones
                        rm -rf $out/opt/xp-pen/lib
                        rm -rf $out/opt/xp-pen/platforms

                        # Copy assets and udev rules
                        cp $dir/App/usr/share/icons/hicolor/256x256/apps/xppentablet.png $out/share/icons/hicolor/256x256/apps/
                        cp $dir/App/usr/share/applications/xppentablet.desktop $out/share/applications/
                        cp $dir/App/lib/udev/rules.d/10-xp-pen.rules $out/lib/udev/rules.d/

                        # Adjust Exec and Icon paths in desktop file
                        substituteInPlace $out/share/applications/xppentablet.desktop \
                          --replace "Exec=/usr/lib/pentablet/PenTablet.sh" "Exec=xp-pen-driver" \
                          --replace "Icon=/usr/lib/pentablet/xppentablet.png" "Icon=xppentablet"

                        # Create wrapper script in bin
                        cat > $out/bin/xp-pen-driver <<EOF
                  #!/bin/sh
                  exec $out/opt/xp-pen/PenTablet "\$@"
                  EOF
                        chmod +x $out/bin/xp-pen-driver

                        # Manually wrap the PenTablet binary since it's not in $out/bin
                        wrapQtApp $out/opt/xp-pen/PenTablet

                        runHook postInstall
                '';

                meta = with prev.lib; {
                  description = "Official drivers for XP-Pen tablet devices";
                  homepage = "https://www.xp-pen.com/";
                  license = licenses.unfree;
                  platforms = platforms.linux;
                  maintainers = [ ];
                };
              };
            };
          in
          lib.mkIf (config.hardware.xpPen.tablets != [ ]) (
            lib.mkMerge [
              {
                nixpkgs.overlays = [
                  xp-pen-overlay
                ]; # Apply the overlay
              }
              (lib.mkIf (builtins.elem "artist-13.3-pro" config.hardware.xpPen.tablets) {
                hardware.uinput.enable = true; # Enable uinput for tablet support
                systemd.tmpfiles.rules = [
                  "L+ /usr/lib/pentablet - - - - ${pkgs.xp-pen-13-3-pro}/opt/xp-pen"
                ]; # Create symlink for proper functionality (package expects to be in fhs)
                environment.systemPackages = [ pkgs.xp-pen-13-3-pro ]; # Install the package
                services.udev.packages = [ pkgs.xp-pen-13-3-pro ]; # Register package's udev rules
              })
            ]
          );
      };
  };
}
