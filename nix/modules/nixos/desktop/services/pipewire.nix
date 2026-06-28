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

      # WirePlumber: enable automatic Bluetooth profile switching.
      # When an application requests the microphone, WirePlumber auto-switches
      # from A2DP (high-quality playback-only) to HSP/HFP (bidirectional audio).
      # Returns to A2DP when the mic is released.
      (mkIf config.core.hardware.bluetooth.enable {
        services.pipewire.wireplumber.extraConfig."10-bluetooth-auto-switch" = {
          "wireplumber.settings" = {
            "bluetooth.autoswitch-to-headset-profile" = true;
          };
          "monitor.bluez.rules" = [
            {
              matches = [
                {
                  "device.name" = "~bluez_card.*";
                }
              ];
              actions = {
                "update-props" = {
                  "bluez5.auto-connect" = [
                    "hfp_hf"
                    "hsp_hs"
                    "a2dp_sink"
                  ];
                };
              };
            }
          ];
        };
      })
    ]);
  }
