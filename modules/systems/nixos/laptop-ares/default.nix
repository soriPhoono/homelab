{ den, ... }: {
  imports = [
    ./disko.nix
  ];

  den.hosts.x86_64-linux.laptop-ares.users.sphoono = { };

  den.aspects.laptop-ares = {
    includes = [
      # -- External libraries --
      den.aspects.stylix
      # -- Gitops updates --
      den.aspects.core.gitops
      # -- Core hardware --
      den.aspects.core.hardware.firmware
      den.aspects.core.hardware.cpu.amd
      den.aspects.core.hardware.gpu.amd
      den.aspects.core.hardware.gpu.nvidia.laptop
      # -- Core OS modules --
      den.aspects.core.bootloaders.systemd-boot
      den.aspects.core.swap.zram
      den.aspects.core.networking.network-manager
      den.aspects.core.networking.tailscale
      # -- Desktop environment --
      den.aspects.desktop.environments.kde
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
      boot.plymouth =
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
      services.asusd.enable = true;
      stylix = {
        enable = true;
        base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";
        # The host picks its own plymouth theme above.
        targets.plymouth.enable = false;
      };
    };
  };

  # host-aspects projects each host aspect's `homeManager` half onto this user.
  # It is applied here rather than on den.aspects.sphoono so that aspect stays
  # shell-only and remains portable to a standalone home.
  den.aspects."sphoono@laptop-ares".includes = [
    den.batteries.primary-user
    den.batteries.host-aspects
  ];
}
