{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.core.hardware.gpu;
in
  with lib; {
    imports = [
      ./intel.nix
      ./amd.nix
      ./nvidia.nix
    ];

    options.core.hardware.gpu = {
      enable = mkEnableOption "Enable graphics driver features";

      dedicated = {
        hardwareAcceleration = {
          enable = mkEnableOption "Enable hardware acceleration on dedicated GPUs (may affect battery life)";
        };
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
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
      }
    ]);
  }
