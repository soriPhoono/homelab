{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.core.shells.fish;
in
  with lib; {
    options.core.shells.fish = {
      enable = mkEnableOption "Enable the fish shell";
    };

    config = mkIf cfg.enable {
      programs.fish = {
        enable = true;

        inherit (config.core.shells) shellAliases;

        plugins = with pkgs; [
          {
            name = "bass";
            src = stdenv.mkDerivation {
              pname = "fish-bass";
              version = "1.0-7-20-18";

              src = fetchFromGitHub {
                owner = "edc";
                repo = "bass";
                rev = "v1.0";
                hash = "sha256-XpB8u2CcX7jkd+FT3AYJtGwBtmNcLXtfMyT/z7gfyQw=";
              };

              buildPhase = ''
                substituteInPlace functions/bass.fish \
                  --replace-fail "python " "${python3}/bin/python3 "
                substituteInPlace functions/__bass.py \
                  --replace-fail "env_reader = \"python -c " "env_reader = \"${python3}/bin/python3 -c "
              '';

              installPhase = ''
                mkdir -p $out
                cp -r . $out
              '';
            };
          }
          {
            name = "sponge";
            src = fetchFromGitHub {
              owner = "meaningful-ooo";
              repo = "sponge";
              rev = "v1.1.0";
              hash = "sha256-MdcZUDRtNJdiyo2l9o5ma7nAX84xEJbGFhAVhK+Zm1w=";
            };
          }
          {
            name = "done";
            src = fetchFromGitHub {
              owner = "franciscolourenco";
              repo = "done";
              rev = "1.21.1";
              hash = "sha256-GZ1ZpcaEfbcex6XvxOFJDJqoD9C5out0W4bkkn768r0=";
            };
          }
          {
            name = "pisces";
            src = fetchFromGitHub {
              owner = "laughedelic";
              repo = "pisces";
              rev = "v0.7.0";
              hash = "sha256-Oou2IeNNAqR00ZT3bss/DbhrJjGeMsn9dBBYhgdafBw=";
            };
          }
        ];

        interactiveShellInit = let
          importEnvironment =
            if lib.hasAttr "environment.env" config.sops.secrets
            then "export (cat ${config.sops.secrets."environment.env".path})"
            else "";

          sessionVariables =
            concatStringsSep
            "\n"
            (mapAttrsToList
              (name: value: "set ${name} \"${value}\"")
              config.core.shells.sessionVariables);
        in ''
          set fish_greeting

          set -U __done_min_cmd_duration 2500

          ${importEnvironment}
          ${sessionVariables}

          ${
            lib.optionalString config.programs.fastfetch.enable ''
              if not set -q SSH_CLIENT
                fastfetch
              end
            ''
          }
        '';
      };
    };
  }
