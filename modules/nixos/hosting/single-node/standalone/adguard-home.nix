{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.single-node.standalone.adguard-home;
in
  with lib; {
    options.hosting.single-node.standalone.adguard-home = {
      enable = mkEnableOption "AdGuard Home DNS server.";
    };

    config = mkIf cfg.enable {
      virtualisation.oci-containers.containers."adguard-home" = {
        image = "adguard/adguardhome:v0.107.72";
        volumes = [
          "adguard-workdir:/opt/adguardhome/work"
          "adguard-config:/opt/adguardhome/conf"
        ];

        ports = [
          # Plain DNS
          "53:53/tcp"
          "53:53/udp"

          # Web interface + HTTPS/DNS-over-HTTPS
          "80:80/tcp"
          "443:443/tcp"
          "443:443/udp"
          "3000:3000/tcp"

          # DNS-over-TLS
          "853:853/tcp"

          # DNScrypt
          "5443:5443/tcp"
          "5443:5443/udp"

          # DNS-over-QUIC
          # "784:784/udp"
          # "853:853/udp"
          # "8853:8853/udp"
        ];
      };
    };
  }
