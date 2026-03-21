{
  lib,
  config,
  ...
}: let
  cfg = config.core.hardware.bluetooth;
in {
  options.core.hardware.bluetooth = {
    enable = lib.mkEnableOption "Enable bluetooth hardware support";
  };

  config = lib.mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;

      settings = {
        General = {
          Experimental = true;

          Enable = "Source,Sink,Media,Socket";
        };
      };
    };
  };
}
