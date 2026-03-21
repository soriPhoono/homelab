{lib, ...}:
with lib; {
  imports = [
    ./traefik.nix
  ];

  options.hosting.single-node.modules.reverse-proxy = {
    enable = mkEnableOption "Enable reverse proxy system for publishing services to a domain name";

    type = mkOption {
      type = with types; nullOr (enum ["traefik"]);
      default = null;
      description = "Type of reverse proxy to use";
    };

    acmeEmail = mkOption {
      type = with types; nullOr str;
      default = null;
      description = "ACME email for certificate registration";
    };
  };
}
