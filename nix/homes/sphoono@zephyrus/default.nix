{
  imports = [
    ./hypr.nix
    ./apps.nix
  ];

  core = {
    shells.shellAliases = {
      lzg = "lazygit";
    };

    # Laptop-specific configs
    syncthing = {
      enable = true;
      tray.enable = true;
      devices = {
        ares = {
          id = "NC65XCZ-XWT3JYR-I4LZVZE-7BYK24J-N4PLNDG-NIKFYII-H5PKCOK-DP53WA3";
          addresses = [
            "tcp://100.92.224.61:22000"
          ];
        };
        phone = {
          id = "MTYZJ3I-XDWC4MU-J72IDUK-QFMZNGB-KHGXFVU-H7CAPB7-FDOSKUE-6LCG2QU";
          addresses = [
            "tcp://100.79.169.76:22000"
          ];
        };
      };
    };
  };
}
