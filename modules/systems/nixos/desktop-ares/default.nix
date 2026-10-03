{ den, ... }: {
  imports = [
    ./disko.nix
  ];
  den = {
    hosts.x86_64-linux.desktop-ares.users.sphoono = { };

    aspects.desktop-ares = {
      includes = [
        # -- External libraries --
        den.aspects.stylix
        # -- Gitops updates --
        den.aspects.core.gitops
        # -- Core hardware --
        den.aspects.core.hardware.firmware
        den.aspects.core.hardware.cpu.intel
        den.aspects.core.hardware.gpu.amd
        # -- Core OS modules --
        den.aspects.core.bootloaders.systemd-boot
        den.aspects.core.swap.zram
        den.aspects.core.networking.network-manager
        den.aspects.core.networking.tailscale
        # -- Desktop environment --
        den.aspects.desktop.greeters.sddm
        den.aspects.desktop.managers.hyprland
        # -- Core desktop features --
        den.aspects.desktop.components.audio
        den.aspects.desktop.components.bluetooth
        # -- Desktop application runtimes --
        den.aspects.desktop.platforms.appimage
        # -- Domains of desktop activity (scoped) --
        den.aspects.desktop.domains.gaming.desktop
        # -- Desktop applications (scoped) --
        den.aspects.desktop.tools.virt-manager
        den.aspects.desktop.tools.partition-manager
        den.aspects.desktop.tools.virtualbox
        # -- External device interaction --
        den.aspects.core.hardware.hid.mice.logitech
        den.aspects.core.hardware.hid.controllers.xbox
        den.aspects.core.hardware.android
      ];
      nixos = { pkgs, ... }: {
        hardware.facter.reportPath = ./facter.json;
        boot = {
          kernelPackages = pkgs.linuxPackages_zen;
          plymouth =
            let
              theme = "connect";
            in
            {
              inherit theme;
              themePackages = [
                (pkgs.adi1090x-plymouth-themes.override {
                  selected_themes = [
                    theme
                  ];
                })
              ];
            };
        };
        stylix = {
          enable = true;
          base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";
          targets.plymouth.enable = false;
        };
      };
    };

    aspects."sphoono@desktop-ares" = {
      includes = [
        den.batteries.primary-user
        den.batteries.host-aspects

        den.aspects.sphoono.desktop.wm.hypr
        den.aspects.sphoono.desktop.wm.shells.noctalia
        den.aspects.sphoono.desktop.wm.supporting
        den.aspects.sphoono.desktop
        den.aspects.sphoono.development
        den.aspects.sphoono.content-creation
      ];

      homeManager = {
        wayland.windowManager.hyprland.settings = {
          monitor = [
            {
              output = "HDMI-A-1";
              mode = "1920x1080@75";
              position = "0x0";
              scale = 1;
            }
          ];
        };
      };
    };
  };
}
