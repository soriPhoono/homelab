{
  lib,
  config,
  ...
}: let
  cfg = config.core.hardware.cpu;
in
  with lib; {
    options.core.hardware.cpu.vendor = mkOption {
      type = types.nullOr (types.enum ["intel" "amd"]);
      description = "The vendor of the cpu";
      default = null;
    };

    config = {
      hardware.cpu = {
        intel = mkIf (cfg.vendor == "intel") {
          updateMicrocode = true;
        };
        amd = mkIf (cfg.vendor == "amd") {
          updateMicrocode = true;
        };
      };
    };
  }
