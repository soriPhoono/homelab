{
  lib,
  config,
  options,
  pkgs,
  ...
}: let
  cfg = config.core.gpg;
  gpgHome = config.programs.gpg.homedir;
in
  with lib; {
    options.core.gpg = {
      enable = mkEnableOption ''
        GPG key management from sops-nix secrets.
        Stores an armored GPG private key in the user secrets vault and deploys
        it to ~/.gnupg on activation, preserving a single GPG identity across
        machines.
      '';

      keyFingerprint = mkOption {
        type = types.str;
        default = "0000000000000000000000000000000000000000";
        description = ''
          Full fingerprint of the GPG key used for trust-db initialization and
          git signing. Must be the 40-hex-char fingerprint without spaces.
        '';
        example = "FF9F589746CBDCE989E5C2D75928BCCDC1E7C015";
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
        warnings = optionals (cfg.keyFingerprint == "0000000000000000000000000000000000000000") [
          "core.gpg.keyFingerprint is still set to the placeholder value. Set it to your actual GPG key fingerprint."
        ];

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

      (mkIf (options ? sops && config.core.secrets.enable) {
        sops.secrets."gpg/primary_key" = {
          path = "${gpgHome}/private.key";
          mode = "0600";
        };

        home.activation.importGpgKey = lib.hm.dag.entryAfter ["writeBoundary"] ''
          gpg_home="${gpgHome}"
          key_file="$gpg_home/private.key"

          if [ -f "$key_file" ]; then
            mkdir -p "$gpg_home"
            chmod 700 "$gpg_home"

            fingerprint="${cfg.keyFingerprint}"
            if ! ${pkgs.gnupg}/bin/gpg --homedir "$gpg_home" --batch --list-secret-keys "$fingerprint" >/dev/null 2>&1; then
              echo "gpg: importing primary key into $gpg_home"
              ${pkgs.gnupg}/bin/gpg --homedir "$gpg_home" --batch --import "$key_file" || true
              { echo trust; echo 5; echo y; echo save; } \
                | ${pkgs.gnupg}/bin/gpg --homedir "$gpg_home" --batch --command-fd 0 --edit-key "$fingerprint" || true
            fi

            rm -f "$key_file"
          fi
        '';
      })
    ]);
  }
