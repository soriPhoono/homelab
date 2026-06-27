{
  lib,
  config,
  nixosConfig,
  options,
  ...
}:
with lib; {
  options.core.ssh.publicKeys = mkOption {
    type = with types; attrsOf str;
    default = {};
    description = ''
      Named public SSH keys. Each key is written to ~/.ssh/id_<name>.pub,
      the corresponding private key is expected at ssh/<name>_key in sops.
    '';
    example = {primary = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA...";};
  };

  config = let
    sshKeys = config.core.ssh.publicKeys;
    homeDir = config.home.homeDirectory;
  in
    mkIf (options ? sops && sshKeys != {}) {
      sops.secrets = mkIf config.core.secrets.enable (mapAttrs' (
          name: _:
            nameValuePair "ssh/${name}_key" {
              path = "${homeDir}/.ssh/id_${name}";
            }
        )
        sshKeys);

      home.file =
        mapAttrs' (
          name: key:
            nameValuePair ".ssh/id_${name}.pub" {
              text = key;
            }
        )
        sshKeys;

      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;

        settings = {
          "*" = {
            IdentityFile = mapAttrsToList (name: _: "${homeDir}/.ssh/id_${name}") sshKeys;

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
