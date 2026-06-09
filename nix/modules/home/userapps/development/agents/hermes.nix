{
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  modulePath = "userapps.development.agents.hermes";
  cfg = config.${modulePath};
  username = config.home.username;

  labels =
    {
      "traefik.enable" = "true";
      "traefik.http.routers.hermes-${username}.rule" = "Host(`ai.local.cryptic-coders.net`) && PathPrefix(`/hermes/${username}`)";
      "traefik.http.routers.hermes-${username}.entrypoints" = "websecure";
      "traefik.http.routers.hermes-${username}.tls" = "true";
      "traefik.http.routers.hermes-${username}.tls.certresolver" = "le";
      "traefik.http.middlewares.hermes-${username}-strip.stripprefix.prefixes" = "/hermes/${username}";
      "traefik.http.routers.hermes-${username}.middlewares" = "hermes-${username}-strip@docker";
      "traefik.http.services.hermes-${username}.loadbalancer.server.port" = "8642";
    }
    // cfg.extraLabels;
in
  with lib; {
    options.${modulePath} = {
      enable = mkEnableOption "Enable the Hermes Agent user service";

      image = mkOption {
        type = types.str;
        default = "ghcr.io/nousresearch/hermes-agent:latest";
        description = "Docker image for Hermes Agent.";
      };

      dataDir = mkOption {
        type = types.str;
        default = "${config.home.homeDirectory}/.hermes";
        description = "Local data directory to mount inside the Hermes container.";
      };

      env = mkOption {
        type = with types; attrsOf str;
        default = {};
        description = "Environment variables to inject into the Hermes container.";
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
          hermes = "${pkgs.docker}/bin/docker exec -it hermes-${username} hermes --tui";
          hermes-acp = "${pkgs.docker}/bin/docker exec -i hermes-${username} hermes acp";
        };

        systemd.user.services.hermes-gateway = {
          Unit = {
            Description = "NousResearch Hermes Agent Gateway";
            After = ["default.target"];
          };
          Service = {
            Type = "simple";
            ExecStartPre = "-${pkgs.docker}/bin/docker rm -f hermes-${username}";
            ExecStart = concatStringsSep " " (
              [
                "${pkgs.docker}/bin/docker run"
                "--name ${escapeShellArg "hermes-${username}"}"
                "--network proxy"
                "-v ${escapeShellArg "${cfg.dataDir}:/opt/data"}"
              ]
              ++ (mapAttrsToList (name: value: "--label ${escapeShellArg "${name}=${value}"}") labels)
              ++ (mapAttrsToList (name: value: "-e ${escapeShellArg "${name}=${value}"}") cfg.env)
              ++ (map escapeShellArg cfg.extraArgs)
              ++ [
                (escapeShellArg cfg.image)
                "gateway run"
              ]
            );
            ExecStop = "${pkgs.docker}/bin/docker stop hermes-${username}";
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
