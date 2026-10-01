{
  den.aspects.sphoono.ssh = _: {
    nixos.users.users.sphoono.openssh.authorizedKeys.keyFiles = [ ./assets/id_primary.pub ];
    homeManager = { config, ... }: {
      home.file.".ssh/id_primary.pub".source = ./assets/id_primary.pub;
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings = {
          "*" = {
            IdentityFile = [ "${config.home.homeDirectory}/.ssh/id_primary" ];
            ForwardAgent = false;
            AddKeysToAgent = "yes";
            Compression = false;
            ServerAliveInterval = 0;
            ServerAliveCountMax = 3;
            HashKnownHosts = false;
            UserKnownHostsFile = "~/.ssh/known_hosts";
            ControlMaster = "no";
            ControlPath = "~/.ssh/master-%r@%n:%p";
            ControlPersist = "no";
          };
        };
      };
      services.ssh-agent.enable = true;
      sops.secrets = {
        "ssh/primary" = {
          path = "${config.home.homeDirectory}/.ssh/id_primary";
          mode = "0400";
        };
      };
    };
  };
}
