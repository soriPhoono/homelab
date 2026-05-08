{
  imports = [
    ./openssh.nix
    ./network-manager.nix
    ./tailscale.nix
  ];

  config = {
    networking = {
      nftables.enable = true;
      useNetworkd = true;
    };

    services.resolved.enable = true;
  };
}
