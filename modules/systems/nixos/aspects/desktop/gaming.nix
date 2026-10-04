{ inputs, den, ... }: {
  flake-file.inputs.ygo-nix.url = "github:digiboid/ygo-nix";

  den.aspects.desktop.domains.gaming = {
    desktop = {
      /**
        Gaming stores:
        - Steam (requires root for mods) (NX+HM)
        - Lutris (primary) (HM)
        - Prismlauncher (minecraft) (HM)

        Dependencies for gaming:
        - Gamemode (NX+HM)
        - Gamescope (NX+HM)
        - Mangohud (HM)
      */

      # programs.steam pulls in the unfree steam package.
      includes = [
        (den.batteries.unfree [
          "steam"
          "steam-unwrapped"
        ])
      ];
      nixos = { pkgs, ... }: {
        programs = {
          gamemode = {
            # Install and configure gamemode
            enable = true;
            enableRenice = true;
          };
          gamescope = {
            # Install and configure gamescope
            enable = true;
            enableWsi = true;
            capSysNice = true;
          };
          steam = {
            enable = true;
            extest.enable = true;
            extraCompatPackages = with pkgs; [
              # Launcher compatibility for mods and shaders
              proton-ge-bin
              steamtinkerlaunch
            ];
          };
        };
      };
      homeManager =
        {
          pkgs,
          osConfig ? null,
          ...
        }:
        {
          home.packages = with pkgs; [
            # Runtime tools
            gamescope
            gamemode
            # Troubleshooting tools
            winetricks
            protontricks
            # Game clients
            gzdoom # Doom with mods
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
            mangohud = {
              enable = true;
              settings.full = true;
            };
            lutris = {
              enable = true;
              defaultWinePackage = pkgs.proton-ge-bin;
              steamPackage = osConfig.programs.steam.package or pkgs.steam;
              extraPackages = with pkgs; [
                # Launcher compatibility for proton
                umu-launcher
              ];
              winePackages = with pkgs; [
                wineWow64Packages.full
              ];
              protonPackages = with pkgs; [
                proton-ge-bin
              ];
            };
            prismlauncher = {
              enable = true;
              # Prism finds its runtimes through PRISMLAUNCHER_JAVA_PATHS,
              # which the nixpkgs wrapper sets from this list -- not by
              # scanning PATH. Putting the JDKs in home.packages instead
              # collides in buildEnv, since every one of them ships bin/java
              # and none carry a meta.priority to break the tie. The wrapper
              # default is [ jdk25 jdk21 jdk17 jdk8 ]; 11 is added for older
              # modpacks.
              package = pkgs.prismlauncher.override {
                jdks = with pkgs; [
                  jdk25
                  jdk21
                  jdk17
                  jdk11
                  jdk8
                ];
              };
            };
          };
        };
    };
    vr = {
      includes = [
        den.aspects.core.hardware.android
      ];
      nixos = {
        services.wivrn = {
          enable = true;
          openFirewall = true;
          autoStart = true;
          highPriority = true;
          steam.implementOXRRuntimes = true;
        };
      };
      homeManager = { pkgs, ... }: {
        home.packages = with pkgs; [
          sidequest
        ];
      };
    }; # TODO: Complete this
  };
}
