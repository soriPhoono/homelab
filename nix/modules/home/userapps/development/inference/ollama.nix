{
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  modulePath = "userapps.development.inference.ollama";
  cfg = config.${modulePath};
  username = config.home.username;

  labels =
    {
      "traefik.enable" = "true";
      "traefik.http.routers.ollama-${username}.rule" = "Host(`ai.local.cryptic-coders.net`) && PathPrefix(`/ollama/${username}`)";
      "traefik.http.routers.ollama-${username}.entrypoints" = "websecure";
      "traefik.http.routers.ollama-${username}.tls" = "true";
      "traefik.http.routers.ollama-${username}.tls.certresolver" = "le";
      "traefik.http.middlewares.ollama-${username}-strip.stripprefix.prefixes" = "/ollama/${username}";
      "traefik.http.routers.ollama-${username}.middlewares" = "ollama-${username}-strip@docker";
      "traefik.http.services.ollama-${username}.loadbalancer.server.port" = "11434";
    }
    // cfg.extraLabels;
in
  with lib; {
    options.${modulePath} = {
      enable = mkEnableOption "Enable Ollama user service running in Docker";

      image = mkOption {
        type = types.str;
        default = "ollama/ollama:latest";
        description = "Docker image for Ollama.";
      };

      dataDir = mkOption {
        type = types.str;
        default = "${config.home.homeDirectory}/.ollama";
        description = "Local data directory to persist Ollama configurations and downloaded models.";
      };

      gpu = mkOption {
        type = types.enum ["cpu" "nvidia" "amd"];
        default = "cpu";
        description = "Type of GPU acceleration to configure.";
      };

      env = mkOption {
        type = with types; attrsOf str;
        default = {};
        description = "Environment variables to inject into the Ollama container.";
      };

      extraArgs = mkOption {
        type = with types; listOf str;
        default = [];
        description = "Extra arguments to pass to the docker run command.";
      };

      extraLabels = mkOption {
        type = with types; attrsOf str;
        default = {};
        description = "Extra Traefik/Docker labels to attach to the container.";
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        core.shells.shellAliases = mkIf (options ? core.shells.shellAliases) {
          ollama = "${pkgs.docker}/bin/docker exec -it ollama-${username} ollama";
        };

        systemd.user.services.ollama-gateway = {
          Unit = {
            Description = "Ollama Local Inference Gateway";
            After = ["default.target"];
          };
          Service = {
            Type = "simple";
            ExecStartPre = "-${pkgs.docker}/bin/docker rm -f ollama-${username}";
            ExecStart = concatStringsSep " " (
              [
                "${pkgs.docker}/bin/docker run"
                "--name ${escapeShellArg "ollama-${username}"}"
                "--network proxy"
                "-v ${escapeShellArg "${cfg.dataDir}:/root/.ollama"}"
              ]
              ++ optionals (cfg.gpu == "nvidia") ["--gpus all"]
              ++ optionals (cfg.gpu == "amd") ["--device /dev/kfd" "--device /dev/dri"]
              ++ (mapAttrsToList (name: value: "--label ${escapeShellArg "${name}=${value}"}") labels)
              ++ (mapAttrsToList (name: value: "-e ${escapeShellArg "${name}=${value}"}") cfg.env)
              ++ (map escapeShellArg cfg.extraArgs)
              ++ [
                (escapeShellArg (
                  if cfg.gpu == "amd" && cfg.image == "ollama/ollama:latest"
                  then "ollama/ollama:rocm"
                  else cfg.image
                ))
              ]
            );
            ExecStop = "${pkgs.docker}/bin/docker stop ollama-${username}";
            Restart = "always";
            RestartSec = "10s";
          };
          Install = {
            WantedBy = ["default.target"];
          };
        };
      }
    ]);
  }
