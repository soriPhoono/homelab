{
  inputs,
  lib,
  config,
  ...
}: let
  cfg = config.core;
in {
  imports = [
    ./nixconf.nix
    ./user.nix
    ./android.nix
  ];

  options.core = {
    timeZone = lib.mkOption {
      type = with lib.types; nullOr str;
      description = "The current system time zone";
      default = null;
      example = "America/Chicago";
    };
  };

  config = {
    time.timeZone = lib.mkIf (cfg.timeZone != null) cfg.timeZone;

    # Dynamically pull the stateVersion from the nixpkgs-droid input
    system.stateVersion = inputs.nixpkgs-droid.lib.trivial.release;
  };
}
