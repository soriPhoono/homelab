{lib, ...}:
with lib; {
  imports = [
    ./n8n.nix
  ];

  options.hosting.ai = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable AI hosting services";
    };
  };
}
