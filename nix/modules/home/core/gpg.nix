{
  lib,
  pkgs,
  config,
  options,
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
          placeholderWarnings = flatten (
            mapAttrsToList (
              name: identity:
                optionals (identity.keyFingerprint == "0000000000000000000000000000000000000000") [
                  "core.gpg.identities.${name}.keyFingerprint is still set to the placeholder value."
                ]
            )
            cfg.identities
          );
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

          pinentry.package = pkgs.writeShellApplication {
            name = "pinentry-script";
            runtimeInputs = [
              pkgs.pinentry-curses
              cfg.pinentryPackage
              pkgs.procps
              pkgs.gnugrep
            ];
            text = ''
              is_ssh=false

              if [ -n "''${SSH_CLIENT:-}" ] || [ -n "''${SSH_TTY:-}" ] || [ -n "''${SSH_CONNECTION:-}" ]; then
                is_ssh=true
              fi

              if [ "$is_ssh" = false ]; then
                target_tty="''${GPG_TTY:-}"
                if [ -z "$target_tty" ] || [ "$target_tty" = "not a tty" ]; then
                  target_tty=$(tty 2>/dev/null || true)
                fi

                if [ -n "$target_tty" ] && [ -e "$target_tty" ]; then
                  tty_short=$(basename "$target_tty")
                  for pid in $(ps -o pid= -t "$tty_short" 2>/dev/null || true); do
                    if [ -r "/proc/$pid/environ" ]; then
                      if grep -q -z "^SSH_CLIENT=\|^SSH_TTY=\|^SSH_CONNECTION=" "/proc/$pid/environ" 2>/dev/null; then
                        is_ssh=true
                        break
                      fi
                    fi
                    curr="$pid"
                    while [ -n "$curr" ] && [ "$curr" -gt 1 ] 2>/dev/null; do
                      comm=$(cat "/proc/$curr/comm" 2>/dev/null || true)
                      if [ "$comm" = "sshd" ]; then
                        is_ssh=true
                        break 2
                      fi
                      curr=$(ps -o ppid= -p "$curr" 2>/dev/null | tr -d ' ' || true)
                    done
                  done
                fi
              fi

              if [ "$is_ssh" = false ]; then
                for pid in $(pgrep -u "$(id -u)" 2>/dev/null || true); do
                  if [ -r "/proc/$pid/environ" ]; then
                    if grep -q -z "^SSH_CLIENT=\|^SSH_TTY=\|^SSH_CONNECTION=" "/proc/$pid/environ" 2>/dev/null; then
                      is_ssh=true
                      break
                    fi
                  fi
                done
              fi

              if [ "$is_ssh" = true ]; then
                export GPG_TTY="''${GPG_TTY:-$(tty 2>/dev/null || echo /dev/tty)}"
                export TERM="''${TERM:-xterm-256color}"
                exec ${lib.getExe pkgs.pinentry-curses} "$@"
              elif [ -n "''${WAYLAND_DISPLAY:-}" ] || [ -n "''${DISPLAY:-}" ]; then
                exec ${lib.getExe cfg.pinentryPackage} "$@"
              else
                export GPG_TTY="''${GPG_TTY:-$(tty 2>/dev/null || echo /dev/tty)}"
                export TERM="''${TERM:-xterm-256color}"
                exec ${lib.getExe pkgs.pinentry-curses} "$@"
              fi
            '';
          };

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

          ${concatStringsSep "\n" (
            mapAttrsToList (name: identity: ''
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
            cfg.identities
          )}
        '';
      })
    ]);
  }
