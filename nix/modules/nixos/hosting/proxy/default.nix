{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.proxy;
in
  with lib; {
    imports = [
      ./docktail.nix
    ];

    options.hosting.proxy = {
      enable = mkEnableOption "Enable proxy services";

      tailscale = {
        enable = mkEnableOption "Enable tailscale based reverse proxying of services to either a tailnet or the internet via tailscale funnel";
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        hosting.proxy = {
          docktail.enable = cfg.tailscale.enable;
        };
      }
    ]);
  }
