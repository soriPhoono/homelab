{
  # ── Monitor Configuration ──────────────────────────────────────────
  desktop.window-managers = {
    shells.noctalia.monitors = ["HDMI-A-1"];
    hyprland = {
      monitors = [
        {
          name = "HDMI-A-1";
          primary = true;
          modeline = {
            width = 1920;
            height = 1080;
            refreshRate = 75;
          };
          position = {
            x = 0;
            y = 0;
          };
          scale = 1.0;
        }
      ];

      settings = {
        env = [
          {
            _args = [
              "AQ_DRM_DEVICES"
              "/dev/dri/card1:/dev/dri/card2"
            ];
          }
        ];
      };
    };
  };
}
