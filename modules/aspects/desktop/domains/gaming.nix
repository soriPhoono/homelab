{ inputs, den, ... }: {
  flake-file.inputs = {
    ygo-nix.url = "github:digiboid/ygo-nix";
    jovian.url = "github:Jovian-Experiments/Jovian-NixOS"; # Look into this if I ever build a steamOS console
  };

  den.aspects.desktop.domains.gaming = {
    __functor =
      _self:
      { host, ... }:
      {
        nixos = {
          assertions = [
            {
              assertion = !(host.hasAspect den.aspects.desktop.domains.gaming);
              message = ''
                `den.aspects.desktop.domains.gaming` is a top level grouping aspect,
                not meant to be included in a host, user, or home.
              '';
            }
          ];
        };
      };
    desktop = {
      # programs.steam pulls in the unfree steam package.
      includes = [
        (den.batteries.unfree [
          "steam"
          "steam-unwrapped"
        ])
      ];
      nixos = { pkgs, ... }: {
        environment.systemPackages = with pkgs; [
          # Core gaming tools (perf mon, mod launcher)
          mangohud
          steamtinkerlaunch
          # Gaming stores
          lutris # Epic, steam, gog, etc...
          prismlauncher # Minecraft w/ mods
          gzdoom # Doom w/ mods
          # ygo-nix fetches game files from a "Latest" GitHub release tag
          # that duelists-unite overwrites in place, so the hash it pins
          # goes stale between releases. Refetch with the current hash
          # until upstream repins it.
          (inputs.ygo-nix.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (_old: {
            unpackPhase = ''
              runHook preUnpack
              unzip -q ${
                pkgs.fetchurl {
                  url = "https://github.com/duelists-unite/omega-releases/releases/download/Latest/linux-x64.zip";
                  hash = "sha256-k9QGnU1PMm5YGcFy9RR0Tdhe9mPXdp18AvTJp7a7U14=";
                }
              }
              unzip -q ${
                pkgs.fetchurl {
                  url = "https://github.com/duelists-unite/omega-releases/releases/download/Latest/Omega_Launcher-Linux.zip";
                  hash = "sha256-e7RHLRp/LGae4Z912oBlsTpPQrMCjXlsd18zQIxZVfo=";
                }
              }
              runHook postUnpack
            '';
          })) # YGO omega (Yu-gi-oh)
        ];
        programs = {
          gamemode.enable = true; # Performance optimization project for linux kernel
          steam = {
            enable = true;
            extest.enable = true; # Wayland input system
            protontricks.enable = true; # Bug fixes and support
            extraPackages = with pkgs; [
              freetype
              pkgsi686Linux.freetype
              fontconfig
              pkgsi686Linux.fontconfig
            ];
            extraCompatPackages = with pkgs; [
              proton-ge-bin
            ];
          };
        };
      };
    };
    console = {

    };
    vr = {

    };
    streaming = {
      nixos = { host, ... }: {
        assertions = [
          {
            assertion = !(host.hasAspect den.aspects.desktop.domains.gaming.streaming);
            message = ''
              `den.aspects.desktop.domains.gaming.streaming` is a top level grouping aspect,
              not meant to be included in a host, user, or home.
            '';
          }
        ];
      };
    };
  };
}
