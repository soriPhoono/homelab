{
  lib,
  config,
  nixosConfig,
  options,
  ...
}:
with lib; {
  options.core.ssh.publicKey = lib.mkOption {
    type = with lib.types; nullOr str;
    default = null;
    description = "Public SSH key to use for authentication";
  };

  config = let
    primaryKey = lib.optionalAttrs (config.core.ssh.publicKey != null) {
      ".ssh/id_ed25519.pub".text = config.core.ssh.publicKey;
    };

    primarySecret = lib.optionalAttrs (config.core.ssh.publicKey != null) {
      "ssh/primary_key".path = "${config.home.homeDirectory}/.ssh/id_ed25519";
    };
  in
    mkIf (options ? sops) {
      sops.secrets = lib.mkIf config.core.secrets.enable primarySecret;

      home.file = primaryKey;

      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;

        settings = {
          "*" = {
            IdentityFile = [
              "${config.home.homeDirectory}/.ssh/id_ed25519"
            ];

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

      services.ssh-agent.enable = !(nixosConfig.programs.ssh.startAgent or false);
    };
}
