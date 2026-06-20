{
  lib,
  config,
  ...
}: let
  cfg = config.desktop.services.pipewire;
in
  with lib; {
    options.desktop.services.pipewire = {
      enable = mkEnableOption "Enable PipeWire audio and video service";
    };

    config = mkIf cfg.enable (mkMerge [
      {
        security.rtkit.enable = true;

        services.pipewire = {
          enable = true;
          audio.enable = true;
          pulse.enable = true;
          jack.enable = true;
          alsa = {
            enable = true;
            support32Bit = true;
          };
        };
      }
    ]);
  }
