{
  lib,
  config,
  ...
}:
with lib; {
  options.core.ssh = {
    publicKey = lib.mkOption {
      type = with lib.types; nullOr str;
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

  config = {
    home.file = let
      extraKeys =
        lib.mapAttrs' (name: contents: {
          name = ".ssh/${name}_key.pub";
          value = {text = contents;};
        })
        config.core.ssh.extraSSHKeys;
    in
      {
        ".ssh/id_ed25519.pub".text = config.core.ssh.publicKey;
      }
      // extraKeys;

    sops.secrets = lib.mkIf config.core.secrets.enable (let
      extraSecrets =
        lib.mapAttrs' (name: _: {
          name = "ssh/${name}_key";
          value = {path = "${config.home.homeDirectory}/.ssh/${name}_key";};
        })
        config.core.ssh.extraSSHKeys;
    in
      {
        "ssh/primary_key".path = "${config.home.homeDirectory}/.ssh/id_ed25519";
      }
      // extraSecrets);

    programs.ssh = {
      enable = true;
      addKeysToAgent = "yes";

      matchBlocks."*" = {
        identityFile =
          ["${config.home.homeDirectory}/.ssh/id_ed25519"]
          ++ (lib.mapAttrsToList (name: _: "${config.home.homeDirectory}/.ssh/${name}_key") config.core.ssh.extraSSHKeys);
      };
    };

    services.ssh-agent.enable = true;
  };
}
