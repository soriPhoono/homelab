{
  den.aspects.sphoono.gpg = {
    homeManager =
      {
        lib,
        pkgs,
        config,
        ...
      }:
      {
        programs.gpg = {
          enable = true;
          mutableKeys = true;
          mutableTrust = true;
        };
        services.gpg-agent = {
          enable = true;
          # GPG is only for email encryption; SSH and git signing use ssh-agent.
          enableSshSupport = false;
          # Headless fallback; desktop aspects override this with their own.
          pinentry.package = lib.mkDefault pkgs.pinentry-curses;
        };
        sops.secrets."gpg/primary".mode = "0600";
        # sops-nix decrypts in its own user service, so import after it rather
        # than from home.activation, which is unordered against it.
        systemd.user.services.gpg-import-primary = {
          Unit = {
            Description = "Import primary GPG key from sops";
            Requires = [ "sops-nix.service" ];
            After = [ "sops-nix.service" ];
          };
          Service = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart =
              let
                fingerprint = "BB20833A2AFD3CA979BCAE320C572D55C04518CF";
              in
              pkgs.writeShellScript "gpg-import-primary" ''
                set -eu
                gpg="${lib.getExe config.programs.gpg.package} --homedir ${config.programs.gpg.homedir} --batch"
                if $gpg --list-secret-keys ${fingerprint} >/dev/null 2>&1; then
                  exit 0
                fi
                $gpg --import ${config.sops.secrets."gpg/primary".path}
                echo "${fingerprint}:6:" | $gpg --import-ownertrust
              '';
          };
          Install.WantedBy = [ "default.target" ];
        };
      };
  };
}
