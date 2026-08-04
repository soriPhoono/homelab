{
  imports = [
    ./hypr.nix
    ./apps.nix
    ./configs
  ];

  core = {
    shells = {
      shellAliases = {
        lzg = "lazygit";

        d = "docker";
        dc = "docker compose";
      };
    };

    # Desktop-specific configs
    syncthing = {
      enable = true;
      tray.enable = true;
      devices = {
        zephyrus = {
          id = "NZNMMPD-ZMC5RLA-VI5W74Y-RD2MCQG-UU7GWAE-2NSWCMR-MOL2C2U-7EOB5AS";
          addresses = [
            "tcp://100.99.139.106:22000"
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
