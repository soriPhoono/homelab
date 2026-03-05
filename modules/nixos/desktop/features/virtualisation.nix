{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.desktop.features.virtualisation;
in
  with lib; {
    options.desktop.features.virtualisation = {
      enable = mkEnableOption "Enable virtualisation";
      mode = mkOption {
        type = with types; enum ["host" "guest"];
        default = "host";
        description = "Mode of virtualisation";
      };
    };

    config = mkIf cfg.enable (mkMerge [
      (mkIf (cfg.mode == "host") {
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
          spiceUSBRedirection.enable = true;
          libvirtd = {
            enable = true;
            qemu = {
              swtpm.enable = true;
              vhostUserPackages = with pkgs; [
                virtiofsd
              ];
            };
          };
        };

        programs.virt-manager = {
          enable = true;
        };

        environment.systemPackages = with pkgs; [
          virtio-win
        ];

        users.extraUsers =
          builtins.mapAttrs (_: _: {
            extraGroups = [
              "libvirtd"
              "kvm"
            ];
          })
          config.core.users;
      })
      (mkIf (cfg.mode == "guest") {
        services = {
          qemuGuest.enable = true;
          spice-vdagentd.enable = true;
        };
      })
    ]);
  }
