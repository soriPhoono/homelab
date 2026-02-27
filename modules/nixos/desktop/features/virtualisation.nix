{
  lib,
  config,
  ...
}: let
  cfg = config.desktop.features.virtualisation;
in {
  options.desktop.features.virtualisation = {
    enable = lib.mkEnableOption "Enable virtualisation";

    talos.enable = lib.mkEnableOption "Enable talos virtualisation";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      boot.kernelModules = ["br_netfilter"];
      boot.kernel.sysctl = {
        "net.ipv4.ip_forward" = 1;
        "net.ipv6.conf.all.disable_ipv6" = 0;
        "net.ipv6.conf.default.disable_ipv6" = 0;
        "net.ipv6.conf.all.forwarding" = 1;
        "net.bridge.bridge-nf-call-iptables" = 1;
        "net.bridge.bridge-nf-call-ip6tables" = 1;
      };

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
            "kvm"
          ];
        })
        config.core.users;
    }
    (lib.mkIf cfg.talos.enable {
      networking.firewall = {
        trustedInterfaces = [
          "docker0"
        ];
        allowedTCPPorts = [
          50000
          6443
        ];
        extraInputRules = ''
          iifname "talos*" accept
        '';
        extraForwardRules = ''
          iifname "talos*" accept
          oifname "talos*" accept
          iifname "docker0" accept
          oifname "docker0" accept
        '';
      };
    })
  ]);
}
