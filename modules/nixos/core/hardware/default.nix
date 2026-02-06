{
  lib,
  config,
  ...
}: let
  cfg = config.core.hardware;
in {
  imports = [
    ./gpu
    ./hid
    ./bluetooth.nix
    ./adb.nix
  ];

  options.core.hardware = {
    enable = lib.mkEnableOption "Enable hardware support";

    reportPath = lib.mkOption {
      type = lib.types.path;
      description = "The default report path for facter input modules";
      example = ./facter.json;
    };
  };

  config = lib.mkIf cfg.enable {
    facter = {
      inherit (cfg) reportPath;
    };
  };
}
