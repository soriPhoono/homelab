{ den, ... }: {
  imports = [
    ./disko.nix
  ];

  den.hosts.x86_64-linux.laptop-ares.users.sphoono = { };

  den.aspects.laptop-ares = {
    includes = [
      den.aspects.systemd-boot
      den.aspects.zram-swap
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
