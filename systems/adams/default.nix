{
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
  ];

  documentation.nixos.enable = false;

  core = {
    secrets = {
      enable = true;
      defaultSopsFile = ./secrets.yaml;
    };

    gitops = {
      enable = true;
      repo = "https://github.com/soriphoono/homelab.git";
      name = "adams";
    };

    networking = {
      network-manager.enable = true;
      tailscale.enable = true;
    };

    users = {
      soriphoono = {
        hashedPassword = "$6$x7n.SUTMtInzs2l4$Ew3Zu3Mkc4zvuH8STaVpwIv59UX9rmUV7I7bmWyTRjomM7QRn0Jt/Pl/JN./IqTrXqEe8nIYB43m1nLI2Un211";
        admin = true;
        shell = pkgs.fish;
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEgxxFcqHVwYhY0TjbsqByOYpmWXqzlVyGzpKjqS8mO7";
      };
    };
  };

  hosting = {
    enable = true;
    blocks = {
      reverse-proxy = {
        type = "traefik";
        domain = {
          fqdn = "cryptic-coders.net";
          provider.type = "cloudflare";
        };
      };
      backends.management = {
        type = "portainer";
        portainer.mode = "server";
      };
    };
  };

  # Workaround: prevent high memory usage during build by forcing single-threaded xz
  # This is needed because pixz can consume excessive RAM during parallel compression in proxmox-lxc builds.
  nixpkgs.overlays = [
    (final: _prev: {
      pixz = final.writeShellScriptBin "pixz" ''
        # pixz wrapper to force low memory usage via xz
        # proxmox-lxc passes -t (tarball mode) which xz doesn't support
        # proxmox-lxc might pass -p (parallelism) which xz doesn't support as -p
        params=()
        while [[ $# -gt 0 ]]; do
          case "$1" in
            -t)
              shift
              ;;
            -p)
              shift
              # Consume thread count argument if present
              if [[ $# -gt 0 ]]; then
                shift
              fi
              ;;
            -p*)
              # Handle -p<number>
              shift
              ;;
            *)
              params+=("$1")
              shift
              ;;
          esac
        done
        exec ${final.xz}/bin/xz -T1 "''${params[@]}"
      '';
    })
  ];
}
