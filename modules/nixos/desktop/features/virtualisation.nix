{
  lib,
  config,
  ...
}: let
  cfg = config.desktop.features.virtualisation;
in {
  options.desktop.features.virtualisation = {
    enable = lib.mkEnableOption "Enable virtualbox";
  };

  config = lib.mkIf cfg.enable {
    boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

    networking.firewall.trustedInterfaces = [
      "virbr0"
    ];

    virtualisation = {
      libvirtd.enable = true;
      spiceUSBRedirection.enable = true;
    };

    programs.virt-manager = {
      enable = true;
    };

    users.extraUsers =
      builtins.mapAttrs (_: _: {
        extraGroups = [
          "libvirtd"
        ];
      })
      config.core.users;
  };
}
