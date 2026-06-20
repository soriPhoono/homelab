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
      enable = mkEnableOption ''
        Enable the core secrets module
      '';

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

    config = mkIf cfg.enable (mkMerge [
      {
        systemd.tmpfiles.rules = concatMap (username: [
          "d /home/${username}/.config/ 0755 ${username} users -"
          "d /home/${username}/.config/sops/ 0700 ${username} users -"
          "d /home/${username}/.config/sops/age/ 0700 ${username} users -"
        ]) (attrNames config.core.users);
      }
      (optionalAttrs (options ? sops) {
        sops = {
          defaultSopsFile = mkIf (cfg.defaultSopsFile != null) cfg.defaultSopsFile;

          age.sshKeyPaths = map (key: key.path) config.services.openssh.hostKeys;

          secrets = mapAttrs' (username: _: {
            name = "users/${username}/age_key";
            value = {
              path = "/home/${username}/.config/sops/age/keys.txt";
              mode = "0400";
              owner = username;
              group = "users";
            };
          }) (filterAttrs (_name: user: user.secrets) config.core.users);
        };
      })
    ]);
  }
