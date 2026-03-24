{
  lib,
  config,
  options,
  ...
}: let
  cfg = config.core.secrets;
in
  with lib; {
    options.core.secrets = {
      enable = mkEnableOption "Enable the core secrets module";

      defaultSopsFile = mkOption {
        type = with types; nullOr path;
        default = null;
        description = ''
          The default secrets file to use for the secrets module.
          This is used when no specific secrets file is provided.
        '';
        example = ./secrets.yaml;
      };
    };

    config = lib.mkIf cfg.enable (mkMerge [
      {
        systemd.tmpfiles.rules = lib.concatMap (username: [
          "d /home/${username}/.config/ 0755 ${username} users -"
          "d /home/${username}/.config/sops/ 0700 ${username} users -"
          "d /home/${username}/.config/sops/age/ 0700 ${username} users -"
        ]) (lib.attrNames config.core.users);
      }
      (lib.optionalAttrs (options ? sops) {
        sops = {
          defaultSopsFile = lib.mkIf (cfg.defaultSopsFile != null) cfg.defaultSopsFile;

          age.sshKeyPaths = map (key: key.path) config.services.openssh.hostKeys;

          secrets =
            lib.mapAttrs' (username: _: {
              name = "users/${username}/age_key";
              value = {
                path = "/home/${username}/.config/sops/age/keys.txt";
                mode = "0400";
                owner = username;
                group = "users";
              };
            })
            config.core.users;
        };
      })
    ]);
  }
