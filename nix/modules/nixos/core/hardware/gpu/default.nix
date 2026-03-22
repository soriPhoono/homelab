{
  lib,
  config,
  ...
}: let
  cfg = config.core.hardware.gpu;
in {
  imports = [
    ./intel.nix
    ./amd.nix
    ./nvidia.nix
  ];

  options.core.hardware.gpu = {
    enable = lib.mkEnableOption "Enable graphics driver features";
  };

  config = lib.mkIf cfg.enable {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
}
