{ den, inputs, ... }: {
  flake-file.inputs.qylock.url = "github:soriPhoono/qylock/girl-coffee-dark-mode";

  den.hosts.x86_64-linux.workstation-ares.users.sphoono = { };

  den.aspects.workstation-ares = {
    includes = [
      # -- External libraries --
      den.aspects.stylix
      # -- Core hardware --
      den.aspects.core.hardware.firmware
      den.aspects.core.hardware.cpu.intel.npu
      den.aspects.core.hardware.gpu.intel.gpgpu
      # -- Core OS modules --
      den.aspects.core.bootloaders.systemd-boot
      den.aspects.core.bootloaders.lts-fallback
      den.aspects.core.swap.zram
      den.aspects.core.networking.network-manager
      den.aspects.core.networking.tailscale
      # -- Desktop environment --
      den.aspects.desktop.greeters.sddm
      den.aspects.desktop.managers.hyprland
      # -- Core desktop features --
      den.aspects.desktop.components.audio
      den.aspects.desktop.components.bluetooth
      den.aspects.desktop.components.gnome.keyring
      den.aspects.desktop.components.gnome.dconf
      # -- Desktop application runtimes --
      den.aspects.desktop.platforms.appimage
      den.aspects.desktop.platforms.flatpak
      # -- Domains of desktop activity (scoped) --
      den.aspects.desktop.domains.gaming.desktop
      # -- Desktop applications (scoped) --
      den.aspects.desktop.tools.partition-manager
      den.aspects.desktop.tools.virtualbox
      # -- External device interaction --
      den.aspects.core.hardware.hid.keyboards.qmk
      den.aspects.core.hardware.hid.mice.logitech
      den.aspects.core.hardware.hid.controllers.xbox
      den.aspects.core.hardware.hid.tablets.weylus
      den.aspects.core.hardware.android
      # -- Hosting --
      den.aspects.hosting.docker
      den.aspects.hosting.podman
      den.aspects.hosting.media
    ];
    nixos =
      { pkgs, ... }:
      {
        imports = [ inputs.qylock.nixosModules.default ];

        stylix = {
          enable = true;
          base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";
          # The host picks its own plymouth theme above.
          targets.plymouth.enable = false;
        };

        fileSystems."/" = {
          device = "/dev/disk/by-uuid/3ac163f0-5eea-4347-911d-269baa85f4a6";
          fsType = "ext4";
        };

        fileSystems."/boot" = {
          device = "/dev/disk/by-uuid/CA4E-D10A";
          fsType = "vfat";
          options = [
            "fmask=0077"
            "dmask=0077"
          ];
        };

        # Hardware manifest
        hardware.facter.reportPath = ./facter.json;

        programs.qylock = {
          enable = true;
          theme = "girl-coffee";
          themeOptions.girl-coffee.themeMode = "dark";
          # Lockscreen comes from the noctalia shell, not qylock-lock.
          quickshell.enable = false;
        };

        # Set your time zone.
        time.timeZone = "America/Chicago";

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
      };
  };

  den.aspects."sphoono@workstation-ares" = {
    includes = [
      den.batteries.primary-user
      den.batteries.host-aspects

      den.aspects.sphoono.core
      den.aspects.sphoono.core.wm.hypr
      den.aspects.sphoono.core.wm.shells.noctalia

      den.aspects.sphoono.development
      den.aspects.sphoono.development.desktop

      den.aspects.hosting.gaming.client
    ];
    homeManager = {
      wayland.windowManager.hyprland.settings = {
        monitor = [
          {
            output = "eDP-1";
            mode = "2880x1800@120";
            position = "0x0";
            scale = 1.5;
          }
        ];
      };
    };
  };
}
