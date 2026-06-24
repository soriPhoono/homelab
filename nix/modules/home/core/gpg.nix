{
  lib,
  config,
  options,
  pkgs,
  ...
}: let
  cfg = config.core.gpg;
  gpgHome = config.programs.gpg.homedir;

  identitySubmodule = _: {
    options = {
      keyFingerprint = lib.mkOption {
        type = lib.types.str;
        description = ''
          Full 40-hex-char fingerprint of the GPG key.
          Used for trust-db initialization and git signing.
        '';
        example = "FF9F589746CBDCE989E5C2D75928BCCDC1E7C015";
      };
    };
  };
in
  with lib; {
    options.core.gpg = {
      enable = mkEnableOption ''
        GPG key management from sops-nix secrets.
        Stores armored GPG private keys in the user secrets vault and deploys
        them to ~/.gnupg on activation, preserving GPG identities across
        machines.
      '';

      identities = mkOption {
        type = with types; attrsOf (submodule identitySubmodule);
        default = {};
        description = ''
          Named GPG identities. Each identity's private key should be stored
          in sops as gpg/<name>_key and will be imported on activation.
        '';
        example = {
          primary.keyFingerprint = "FF9F589746CBDCE989E5C2D75928BCCDC1E7C015";
        };
      };

      pinentryPackage = mkOption {
        type = types.package;
        default = pkgs.pinentry-curses;
        description = ''
          Pinentry package for GPG agent passphrase prompts.
          Override in host-specific home configs to match the desktop environment
          (e.g. pinentry-gnome3 for Hyprland, pinentry-qt for KDE Plasma).
        '';
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        warnings = let
          placeholderWarnings = flatten (mapAttrsToList (
              name: identity:
                optionals (identity.keyFingerprint == "0000000000000000000000000000000000000000") [
                  "core.gpg.identities.${name}.keyFingerprint is still set to the placeholder value."
                ]
            )
            cfg.identities);
          noIdentitiesWarning = optionals (cfg.identities == {}) [
            "core.gpg.identities is empty — no GPG keys will be deployed."
          ];
        in
          placeholderWarnings ++ noIdentitiesWarning;

        programs.gpg = {
          enable = true;
          mutableKeys = true;
          mutableTrust = true;
        };

        services.gpg-agent = {
          enable = true;
          enableSshSupport = true;
          enableExtraSocket = true;

          pinentry.package = cfg.pinentryPackage;

          defaultCacheTtl = 3600;
          maxCacheTtl = 86400;
        };

        services.ssh-agent.enable = mkIf (options ? sops) (mkForce false);
      }

      (mkIf (options ? sops && config.core.secrets.enable && cfg.identities != {}) {
        sops.secrets =
          mapAttrs' (
            name: _identity:
              nameValuePair "gpg/${name}_key" {
                path = "${gpgHome}/${name}.key";
                mode = "0600";
              }
          )
          cfg.identities;

        home.activation.importGpgKey = lib.hm.dag.entryAfter ["writeBoundary"] ''
          gpg_home="${gpgHome}"

          ${concatStringsSep "\n" (mapAttrsToList (name: identity: ''
              key_file="$gpg_home/${name}.key"
              fingerprint="${identity.keyFingerprint}"

              if [ -f "$key_file" ] && [ "$fingerprint" != "0000000000000000000000000000000000000000" ]; then
                mkdir -p "$gpg_home"
                chmod 700 "$gpg_home"

                if ! ${pkgs.gnupg}/bin/gpg --homedir "$gpg_home" --batch --list-secret-keys "$fingerprint" >/dev/null 2>&1; then
                  echo "gpg: importing ${name} key into $gpg_home"
                  ${pkgs.gnupg}/bin/gpg --homedir "$gpg_home" --batch --import "$key_file" || true
                  { echo trust; echo 5; echo y; echo save; } \
                    | ${pkgs.gnupg}/bin/gpg --homedir "$gpg_home" --batch --command-fd 0 --edit-key "$fingerprint" || true
                fi

                rm -f "$key_file"
              fi
            '')
            cfg.identities)}
        '';
      })
    ]);
  }
