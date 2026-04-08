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
      enableVirtManager = mkEnableOption "Enable virtualisation with virt-manager";
      enableVirtualBox = mkEnableOption "Enable VirtualBox virtualisation";
      mode = mkOption {
        type = with types; enum ["host" "guest"];
        default = "host";
        description = "Mode of virtualisation";
      };
    };

    config = mkMerge [
      (mkIf (cfg.enableVirtManager && cfg.mode == "host") {
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
      (mkIf (cfg.enableVirtManager && cfg.mode == "guest") {
        services = {
          qemuGuest.enable = true;
          spice-vdagentd.enable = true;
        };
      })
      (mkIf cfg.enableVirtualBox {
        virtualisation.virtualbox.host = {
          enable = true;
          enableExtensionPack = true;
        };

        users.extraUsers =
          builtins.mapAttrs (_: _: {
            extraGroups = [
              "vboxusers"
            ];
          })
          config.core.users;
      })
    ];
  }
