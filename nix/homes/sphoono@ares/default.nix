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
        # zephyrus = {
        #   id = "";
        #   addresses = [
        #     "tcp://[IP_ADDRESS]"
        #   ];
        # };
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
