{
  imports = [
    ./openssh.nix
    ./network-manager.nix
    ./tailscale.nix
    ./netbird.nix
  ];

  config = {
    networking = {
      nftables.enable = true;
      useNetworkd = true;
    };

    services.resolved.enable = true;
  };
}
