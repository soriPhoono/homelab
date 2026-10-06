{ den, inputs, ... }: {
  flake-file.inputs.qylock = {
    # Fork carries girl-coffee themeMode until Darkkal44/qylock#112 merges.
    url = "github:soriPhoono/qylock/girl-coffee-dark-mode";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  imports = [
    ./disko.nix
  ];
  den = {
    hosts.x86_64-linux.desktop-ares.users.sphoono = { };

    aspects.desktop-ares = {
      includes = [
        # -- External libraries --
        den.aspects.stylix
        # -- Core hardware --
        den.aspects.core.hardware.firmware
        den.aspects.core.hardware.cpu.intel
        den.aspects.core.hardware.gpu.intel
        den.aspects.core.hardware.gpu.amd.gpgpu
        # -- Core OS modules --
        den.aspects.core.bootloaders.systemd-boot
        den.aspects.core.swap.zram
        den.aspects.core.networking.network-manager
        den.aspects.core.networking.tailscale
        den.aspects.core.networking.openssh
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
        # -- Hosting --
        den.aspects.hosting.docker
        den.aspects.hosting.podman
        den.aspects.hosting.microserver.media
        den.aspects.hosting.gaming.host
        den.aspects.hosting.trading
      ];
      nixos = { pkgs, ... }: {
        imports = [ inputs.qylock.nixosModules.default ];
        hosting = {
          microserver.media.jellyfin = {
            renderDevice = "/dev/dri/renderD128";
            cardDevice = "/dev/dri/card1";
          };
          gaming.wolf = {
            # Both nodes of the AMD dGPU (pci-0000:03:00.0); card1 is the iGPU.
            renderDevice = "/dev/dri/renderD129";
            cardDevice = "/dev/dri/card2";
            internalMac = "c2:d8:de:57:c6:7c";
          };
        };
        programs.qylock = {
          enable = true;
          theme = "girl-coffee";
          themeOptions.girl-coffee.themeMode = "dark";
          # Lockscreen comes from the noctalia shell, not qylock-lock.
          quickshell.enable = false;
        };
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
        den.aspects.sphoono.desktop.syncthing
        den.aspects.sphoono.desktop.trading
        den.aspects.sphoono.development
        den.aspects.sphoono.content-creation
        den.aspects.hosting.gaming.client
      ];

      homeManager = {
        wayland.windowManager.hyprland.settings = {
          monitor = [
            {
              output = "HDMI-A-5";
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
