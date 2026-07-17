{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.desktop.services.virtualization;
in
  with lib; {
    options.desktop.services.virtualization = {
      enable = mkEnableOption "Enable virtualization with virt-manager";
      mode = mkOption {
        type = with types;
          enum [
            "host"
            "guest"
          ];
        default = "host";
        description = ''
          Mode of virtualization for this machine.
          - "host": Run VMs with virt-manager and libvirtd (desktop/workstation).
          - "guest": Run as a QEMU guest with spice-vdagent (VM).
        '';
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
          (runCommand "virtio-win-symlinked" {} ''
            mkdir -p $out/share/virtio-win
            ln -s ${virtio-win.src} $out/share/virtio-win/virtio-win.iso
          '')
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
        services.qemuGuest.enable = true;
        services.spice-vdagentd.enable = true;
      })
    ]);
  }
