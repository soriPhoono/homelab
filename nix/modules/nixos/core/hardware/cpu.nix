{
  lib,
  config,
  ...
}: let
  cfg = config.core.hardware.cpu;
in
  with lib; {
    options.core.hardware.cpu = {
      enable = mkEnableOption "Enable CPU microcode updates";

      vendor = mkOption {
        type = types.nullOr (types.enum ["intel" "amd"]);
        description = ''
          The CPU vendor for microcode update selection.
          Set to "intel" or "amd" to enable the appropriate CPU microcode
          updates for security and stability fixes. Leave as null to
          skip microcode updates (not recommended).
        '';
        default = null;
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        hardware.cpu = {
          intel = mkIf (cfg.vendor == "intel") {
            updateMicrocode = true;
          };
          amd = mkIf (cfg.vendor == "amd") {
            updateMicrocode = true;
          };
        };
      }
    ]);
  }
