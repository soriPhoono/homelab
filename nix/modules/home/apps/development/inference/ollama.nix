{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.apps.development.inference.ollama;
in
  with lib; {
    options.apps.development.inference.ollama = {
      enable = mkEnableOption "The ollama local llm execution engine";
      acceleration = {
        type = mkOption {
          type = types.nullOr (types.enum ["cuda" "rocm"]);
          default = null;
          example = "rocm";
        };
      };
      loadModels = mkOption {
        type = types.listOf types.str;
        apply = builtins.filter (model: model != "");
        default = [];
        example = [
          "llama3"
          "mistral"
        ];
        description = ''
          List of Ollama models to download automatically via a systemd user service after Ollama starts.
        '';
      };
      syncModels = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Synchronize all currently installed models with those declared in `loadModels`,
          removing any models that are installed but not currently declared there.
        '';
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        services.ollama = {
          enable = true;
          acceleration = cfg.acceleration.type;
        };

        systemd.user.services.ollama-model-loader = mkIf (cfg.loadModels != [] || cfg.syncModels) {
          Unit = {
            Description = "Download ollama models in the background";
            Wants = ["network-online.target"];
            After = [
              "ollama.service"
              "network-online.target"
            ];
            BindsTo = ["ollama.service"];
          };

          Service = {
            Type = "exec";
            Restart = "on-failure";
            RestartSec = "1s";
            RestartMaxDelaySec = "2h";
            RestartSteps = "10";
            Environment = [
              "OLLAMA_HOST=${config.services.ollama.host}:${toString config.services.ollama.port}"
            ];
            ExecStart = let
              ollama = getExe (
                if cfg.acceleration.type == null
                then config.services.ollama.package
                else config.services.ollama.package.override {acceleration = cfg.acceleration.type;}
              );
              binaryInputs = mapAttrs (_: getExe) {
                awk = pkgs.gawk;
                sed = pkgs.gnused;
              };
              inherit (binaryInputs) awk sed;

              nproc = getExe' pkgs.coreutils "nproc";
              xargs = getExe' pkgs.findutils "xargs";

              declaredModelsRegex = pipe cfg.loadModels [
                (map escapeRegex)
                (concatStringsSep "|")
                (escape ["/"])
                escapeShellArg
              ];

              loaderScript = pkgs.writeShellScript "ollama-model-loader" ''
                ${optionalString cfg.syncModels ''
                  installed=$('${ollama}' list | '${awk}' 'NR > 1 {print $1}')
                  ${
                    if (cfg.loadModels != [])
                    then ''
                      echo declared models regex: ${declaredModelsRegex}
                      undeclared=$(echo "$installed" | '${sed}' -E /${declaredModelsRegex}/d)
                    ''
                    else ''
                      undeclared="$installed"
                    ''
                  }
                  if [ -n "$undeclared" ]; then
                    echo removing: $undeclared
                    '${ollama}' rm $undeclared
                  fi
                ''}

                printf "%s\0" ${escapeShellArgs cfg.loadModels} | '${xargs}' -0 -r -n 1 -P "$('${nproc}')" '${ollama}' pull
              '';
            in "${loaderScript}";
          };

          Install = {
            WantedBy = [
              "default.target"
              "ollama.service"
            ];
          };
        };
      }
    ]);
  }
