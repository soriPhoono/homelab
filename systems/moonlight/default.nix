{
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
  ];

  nix.settings.sandbox = false;

  core = {
    hardware.gpu.dedicated.amd.enable = true;

    gitops = {
      enable = true;
      repo = "https://github.com/soriphoono/homelab.git";
      name = "moonlight";
    };

    networking = {
      lxc.enable = true;
      tailscale.enable = true;
    };

    users = {
      soriphoono = {
        hashedPassword = "$6$x7n.SUTMtInzs2l4$Ew3Zu3Mkc4zvuH8STaVpwIv59UX9rmUV7I7bmWyTRjomM7QRn0Jt/Pl/JN./IqTrXqEe8nIYB43m1nLI2Un211";
        admin = true;
        shell = pkgs.fish;
        extraGroups = ["input"];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEgxxFcqHVwYhY0TjbsqByOYpmWXqzlVyGzpKjqS8mO7";
      };
    };
  };

  hosting = {
    enable = true;
    blocks.backends.type = "docker";
    blocks.features.docker-games-server = {
      enable = true;
      openFirewall = true;
      dataDir = "/mnt/games";
    };
  };
}
