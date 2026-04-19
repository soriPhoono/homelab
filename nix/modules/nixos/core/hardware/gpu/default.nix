{
  lib,
  pkgs,
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

    dedicated = {
      hardwareAcceleration = {
        enable = lib.mkEnableOption "Enable hardware acceleration on dedicated GPUs (may affect battery life)";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;

      extraPackages = with pkgs; [
        vulkan-loader
        vulkan-validation-layers
        vulkan-extension-layer
      ];

      extraPackages32 = with pkgs; [
        vulkan-loader
      ];
    };
  };
}
