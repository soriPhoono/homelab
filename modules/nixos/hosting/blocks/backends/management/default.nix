{lib, ...}:
with lib; {
  imports = [
    ./portainer.nix
  ];

  options.hosting.blocks.backends.management = {
    enable = mkEnableOption "Enable management backend";
    type = mkOption {
      type = types.enum ["portainer" "komodo"];
      default = "portainer";
      description = "Type of management service to use";
      example = "komodo";
    };
  };
}
