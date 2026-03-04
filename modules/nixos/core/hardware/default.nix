{
  lib,
  config,
  options,
  ...
}: let
  cfg = config.core.hardware;
in {
  imports = [
    ./gpu
    ./hid
    ./adb.nix
    ./bluetooth.nix
  ];

  options.core.hardware = {
    enable = lib.mkEnableOption "Enable hardware support";

    reportPath = lib.mkOption {
      type = lib.types.path;
      description = "The default report path for facter input modules";
      example = ./facter.json;
    };
  };

  config = lib.mkIf cfg.enable (lib.optionalAttrs (options ? facter) {
    facter = {
      inherit (cfg) reportPath;
    };
  });
}
