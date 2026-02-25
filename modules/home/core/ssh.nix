{
  lib,
  config,
  ...
}: let
  cfg = config.core.ssh;
in
  with lib; {
    options.core.ssh = {
      publicKey = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        description = "Public SSH key to use for authentication";
      };

      extraSSHKeys = mkOption {
        type = with types; attrsOf str;
        description = ''
          An attrset of path on disk/secret in vault containing
          the private key for this ssh key, will also be appended
          with .pub for public key
        '';
        default = {};
        example = {
          "school" = "ssh-ed25519 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
        };
      };
    };

    config = let
      extraKeys =
        lib.mapAttrs' (name: contents: {
          name = ".ssh/${name}_key.pub";
          value = {text = contents;};
        })
        config.core.ssh.extraSSHKeys;
      primaryKey = lib.optionalAttrs (config.core.ssh.publicKey != null) {
        ".ssh/id_ed25519.pub".text = config.core.ssh.publicKey;
      };
      extraSecrets =
        lib.mapAttrs' (name: _: {
          name = "ssh/${name}_key";
          value = {path = "${config.home.homeDirectory}/.ssh/${name}_key";};
        })
        config.core.ssh.extraSSHKeys;
      primarySecret = lib.optionalAttrs (config.core.ssh.publicKey != null) {
        "ssh/primary_key".path = "${config.home.homeDirectory}/.ssh/id_ed25519";
      };
    in {
      home = {
        file = lib.mkIf config.core.secrets.enable (primaryKey // extraKeys);

        activation = {
          copySSHConfig = lib.hm.dag.entryAfter ["linkGeneration"] ''
            # By default home-manager creates a symlink to a Nix store file owned by nobody.
            # This breaks openSSH's strict permission requirements.
            if [ -L ${config.home.homeDirectory}/.ssh/config ]; then
              real_config=$(readlink -f ${config.home.homeDirectory}/.ssh/config)
              rm ${config.home.homeDirectory}/.ssh/config
              cp $real_config ${config.home.homeDirectory}/.ssh/config
              chmod 0600 ${config.home.homeDirectory}/.ssh/config
            fi
          '';
        };
      };

      sops.secrets = lib.mkIf config.core.secrets.enable (primarySecret // extraSecrets);

      programs.ssh = {
        enable = true;

        enableDefaultConfig = false;

        extraConfig = ''
          AddKeysToAgent yes
        '';

        matchBlocks = {
          "*" = {
            identityFile =
              [
                "${config.home.homeDirectory}/.ssh/id_ed25519"
              ]
              ++ (lib.mapAttrsToList (name: _: "${config.home.homeDirectory}/.ssh/${name}_key") cfg.extraSSHKeys);

            forwardAgent = false;
            addKeysToAgent = "no";
            compression = false;
            serverAliveInterval = 0;
            serverAliveCountMax = 3;
            hashKnownHosts = false;
            userKnownHostsFile = "~/.ssh/known_hosts";
            controlMaster = "no";
            controlPath = "~/.ssh/master-%r@%n:%p";
            controlPersist = "no";
          };
        };
      };

      services.ssh-agent.enable = true;
    };
  }
