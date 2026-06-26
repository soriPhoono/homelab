{
  lib,
  config,
  ...
}: let
  modulePath = "userapps.development.agents.hermes";
  cfg = config.${modulePath};
in
  with lib; {
    options.${modulePath} = {
      enable = mkEnableOption "Enable hermes agent";
    };

    config = mkIf cfg.enable (mkMerge [
      {
        xdg.desktopEntries.hermes-desktop = {
          name = "Hermes Desktop";
          comment = "Hermes AI Agent - Desktop UI";
          icon = "${pkgs.hermes-desktop}/share/hermes-desktop/dist/hermes.png";
          exec = "${pkgs.hermes-desktop}/bin/hermes-desktop";
          terminal = false;
          type = "Application";
          categories = ["Development" "Utility"];
          startupNotify = true;
        };
      }
      (mkIf (options ? sops) {
        })
    ]);
  }
