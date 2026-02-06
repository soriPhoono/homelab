{
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
  ];

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
      tailscale = {
        enable = true;
        auth = {
          enable = true;
          internal = true;
        };
      };
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
    mode = "single-node";
    configuration.single-node = {
      domainName = "cryptic-coders.net";
      portainerMode = "server";
    };
  };
}
