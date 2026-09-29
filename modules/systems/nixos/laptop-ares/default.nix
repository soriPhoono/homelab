{ den, ... }: {
  imports = [
    ./disko.nix
  ];

  den.hosts.x86_64-linux.laptop-ares.users.sphoono = { };

  den.aspects.laptop-ares = {
    includes = [
      # Gitops updates
      den.aspects.core.gitops
      # Core hardware
      den.aspects.core.hardware.firmware
      den.aspects.core.hardware.cpu.amd
      den.aspects.core.hardware.gpu.amd
      den.aspects.core.hardware.gpu.nvidia.laptop
      den.aspects.core.hardware.bluetooth
      # Core OS modules
      den.aspects.core.bootloaders.systemd-boot
      den.aspects.core.swap.zram
      den.aspects.core.networking.network-manager
      den.aspects.core.networking.tailscale
      # Core desktop features
      den.aspects.desktop.components.audio
      den.aspects.desktop.components.location
      # Desktop application runtimes
      den.aspects.desktop.platforms.appimage
      # flatpak needs a portal backend (xdg.portal.extraPortals); wire it up
      # once hyprland (and its own portal) lands on this host.
      # den.aspects.desktop.platforms.flatpak
      # Domains of desktop activity (scoped)
      den.aspects.desktop.domains.gaming.desktop
      # Desktop applications (scoped)
      den.aspects.desktop.tools.asusd
      den.aspects.desktop.tools.virt-manager
      den.aspects.desktop.tools.partition-manager
      den.aspects.desktop.tools.virtualbox
      # External device interaction
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
    };
  };

  den.aspects."sphoono@laptop-ares".includes = [
    den.batteries.primary-user
  ];
}
