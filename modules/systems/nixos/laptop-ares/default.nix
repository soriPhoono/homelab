{ den, ... }: {
  imports = [
    ./disko.nix
  ];

  den.hosts.x86_64-linux.laptop-ares.users.sphoono = { };

  den.aspects.laptop-ares = {
    includes = [
      den.aspects.core.hardware.firmware
      den.aspects.core.hardware.cpu.amd
      den.aspects.core.hardware.gpu.amd
      den.aspects.core.hardware.gpu.nvidia.laptop
      den.aspects.core.hardware.bluetooth

      den.aspects.core.bootloaders.systemd-boot
      den.aspects.core.swap.zram-swap

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
