{
  den = {
    aspects.desktop.tools.virt-manager = {
      nixos = { pkgs, ... }: {
        boot = {
          kernelModules = [ "br_netfilter" ];
          kernel.sysctl = {
            "net.ipv4.ip_forward" = 1;
            "net.ipv4.conf.all.forwarding" = 1;
            "net.ipv6.conf.all.disable_ipv6" = 0;
            "net.ipv6.conf.default.disable_ipv6" = 0;
            "net.ipv6.conf.all.forwarding" = 1;
            "net.bridge.bridge-nf-call-iptables" = 1;
            "net.bridge.bridge-nf-call-ip6tables" = 1;
          };
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
          (runCommand "virtio-win-symlinked" { } ''
            mkdir -p $out/share/virtio-win
            ln -s ${virtio-win.src} $out/share/virtio-win/virtio-win.iso
          '')
        ];
      };
    };
    schema.host.includes = [
      ({ user, ... }: {
        nixos.users.groups =
          let
            userName = [ user.userName ];
          in
          {
            libvirtd.members = userName;
            kvm.members = userName;
          };
      })
    ];
  };
}
