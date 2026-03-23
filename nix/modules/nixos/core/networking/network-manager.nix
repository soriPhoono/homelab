{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.core.networking.network-manager;
in {
  options.core.networking.network-manager = {
    enable = lib.mkEnableOption "Enable network manager for managed networking on desktops";
  };

  config = lib.mkIf cfg.enable {
    systemd.network.wait-online.enable = lib.mkForce false;

    networking.networkmanager = {
      enable = true;

      plugins = with pkgs; [
        networkmanager-openconnect
      ];

      wifi = {
        powersave = true;
        macAddress = "random";
      };

      ethernet.macAddress = "random";
    };

    users.extraUsers =
      builtins.mapAttrs (_: _: {
        extraGroups = [
          "networkmanager"
        ];
      })
      config.core.users;
  };
}
