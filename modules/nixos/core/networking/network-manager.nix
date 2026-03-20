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
    assertions = [
      {
        assertion = !config.core.networking.lxc.enable;
        message = "NetworkManager and LXC cannot be enabled at the same time";
      }
      {
        assertion = !config.core.networking.qemu.enable;
        message = "NetworkManager and QEMU cannot be enabled at the same time";
      }
    ];

    systemd.network.wait-online.enable = lib.mkForce false;

    networking.networkmanager = {
      enable = true;

      plugins = with pkgs; [
        networkmanager-openconnect
      ];

      dns = "systemd-resolved";

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
