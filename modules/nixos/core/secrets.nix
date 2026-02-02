{
  lib,
  config,
  ...
}: let
  cfg = config.core.secrets;
in
  with lib; {
    options.core.secrets = {
      enable = lib.mkEnableOption "Enable the core secrets module";

      defaultSopsFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          The default secrets file to use for the secrets module.
          This is used when no specific secrets file is provided.
        '';
        example = ./secrets.yaml;
      };
    };

    config = lib.mkIf cfg.enable {
      systemd.tmpfiles.rules = let
        usersWithSecrets =
          lib.filterAttrs (
            name: _:
              config.home-manager.users.${name}.core.secrets.enable or false
          )
          config.core.users;
      in
        lib.concatMap (username: [
          "d /home/${username}/.config/ 0755 ${username} users -"
          "d /home/${username}/.config/sops/ 0700 ${username} users -"
          "d /home/${username}/.config/sops/age/ 0700 ${username} users -"
        ]) (lib.attrNames usersWithSecrets);

      sops = {
        defaultSopsFile = lib.mkIf (cfg.defaultSopsFile != null) cfg.defaultSopsFile;

        age.sshKeyPaths = map (key: key.path) config.services.openssh.hostKeys;

        secrets = let
          usersWithSecrets =
            lib.filterAttrs (
              name: _:
                config.home-manager.users.${name}.core.secrets.enable or false
            )
            config.core.users;
        in
          lib.mapAttrs' (username: _: {
            name = "users/${username}/age_key";
            value = {
              path = "/home/${username}/.config/sops/age/keys.txt";
              mode = "0400";
              owner = username;
              group = "users";
            };
          })
          usersWithSecrets;
      };
    };
  }
