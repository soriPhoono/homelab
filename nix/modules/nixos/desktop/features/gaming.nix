{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.desktop.features.gaming;
in {
  options.desktop.features.gaming = {
    enable = lib.mkEnableOption "Enable steam integration";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      moonlight-qt
    ];
  };
}
