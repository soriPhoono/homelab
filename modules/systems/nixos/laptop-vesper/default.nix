{ den, ... }:
{
  imports = [
    ./disko.nix
  ];

  den.hosts.x86_64-linux.laptop-vesper.users.spookyskelly = { };

  den.aspects.laptop-vesper = {
    includes = [
      # -- Core hardware --
      den.aspects.core.hardware.firmware
      den.aspects.core.hardware.cpu.intel
      den.aspects.core.hardware.gpu.intel
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
      # -- Domains of desktop activity (scoped) --
      den.aspects.desktop.domains.gaming.desktop
      # -- Desktop applications (scoped) --
      den.aspects.desktop.tools.partition-manager
      # -- External device interaction --
      den.aspects.core.hardware.hid.tablets.xp-pen
      den.aspects.core.hardware.hid.controllers.xbox
      den.aspects.core.hardware.android
      # -- Hosting --
      den.aspects.hosting.docker
      den.aspects.hosting.podman
      den.aspects.hosting.microserver.media
    ];
    nixos = { pkgs, ... }: {
      hardware.facter.reportPath = ./facter.json;
      core.hardware.xpPen.tablets = [ "artist-13.3-pro" ];
      hosting.microserver.media.jellyfin = {
        renderDevice = "/dev/dri/renderD128";
        cardDevice = "/dev/dri/card1";
      };
      boot = {
        kernelPackages = pkgs.linuxPackages_zen;
        plymouth =
          let
            theme = "connect";
          in
          {
            enable = true;
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

  den.aspects."spookyskelly@laptop-vesper".includes = [
    den.batteries.primary-user
    den.batteries.host-aspects

    den.aspects.hosting.gaming.client
  ];
}
