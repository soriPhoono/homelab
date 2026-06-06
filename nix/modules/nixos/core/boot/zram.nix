{
  lib,
  config,
  ...
}: let
  cfg = config.core.boot.zram;
in
  with lib; {
    options.core.boot.zram = {
      enable = mkEnableOption ''
        Enable zram over swap for better performance on swap reads & writes
      '';
    };

    config = mkIf cfg.enable (mkMerge [
      {
        zramSwap = {
          enable = true;
          algorithm = "zstd";
          priority = 5;
        };
      }
    ]);
  }
