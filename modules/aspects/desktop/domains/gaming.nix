{ inputs, ... }: {
  flake-file.inputs = {
    ygo-nix.url = "github:digiboid/ygo-nix";
    jovian.url = "github:Jovian-Experiments/Jovian-NixOS"; # Look into this if I ever build a steamOS console
  };

  den.aspects.desktop.domains.gaming = {
    desktop = {
      nixos = { pkgs, ... }: {
        environment.systemPackages = with pkgs; [
          # Core gaming tools (perf mon, mod launcher)
          mangohud
          steamtinkerlaunch
          # Gaming stores
          lutris # Epic, steam, gog, etc...
          prismlauncher # Minecraft w/ mods
          gzdoom # Doom w/ mods
          inputs.ygo-nix.packages.${pkgs.stdenv.hostPlatform.system}.default # YGO omega (Yu-gi-oh)
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
  };
}
