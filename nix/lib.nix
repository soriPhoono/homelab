_final: prev:
with prev; {
  homelab = {
    helpers = {
      core = {
        discover = dir:
          prev.mapAttrs'
          (name: _: {
            name = prev.removeSuffix ".nix" name;
            value = dir + "/${name}";
          })
          (
            prev.filterAttrs (
              name: type:
                (type == "directory" && builtins.pathExists (dir + "/${name}/default.nix"))
                || (type == "regular" && name != "default.nix" && prev.hasSuffix ".nix" name)
            ) (builtins.readDir dir)
          );
      };
    };

    containers = {
      # NixOS
      mkContainerOption = {
        name,
        description,
        extraOptions ? {},
        ...
      }:
        {
          enable = mkEnableOption "Enable ${name}: ${description}";

          container.publication = mkOption {
            type = types.listOf (types.enum ["tailscale" "cloudflare"]);
            default = [];
            description = ''
              Determines where the container is published to. "local" for the local
              loopback via a reverse proxy, "tailscale" for the tailscale network via docktail,
              "cloudflare" for the cloudflare network via dockflare.
              If multiple are specified, the container will be published to all of them.
            '';
          };
        }
        // extraOptions;

      mkContainer = {
        config,
        cfg,
        image,
        serviceName ? null,
        containerPort ? null,
        ...
      }:
        mkMerge [
          {
            inherit image;

            labels = let
              hostname = config.networking.hostName;
            in
              mkMerge [
                (mkIf (elem "tailscale" (cfg.container.publication or [])) (
                  {
                    "docktail.service.enable" = "true";
                    "docktail.service.network" = "tailscale";
                    "docktail.service.service-port" = "80";
                    "docktail.service.service-protocol" = "http";
                    "docktail.service.1.enable" = "true";
                    "docktail.service.1.service-port" = "443";
                    "docktail.service.1.service-protocol" = "https";
                  }
                  // optionalAttrs (serviceName != null) {
                    "docktail.service.name" = "${hostname}-${serviceName}";
                    "docktail.service.1.name" = "${hostname}-${serviceName}";
                  }
                  // optionalAttrs (containerPort != null) {
                    "docktail.service.port" = toString containerPort;
                    "docktail.service.1.port" = toString containerPort;
                  }
                ))
              ];
          }
          (mkIf (elem "tailscale" (cfg.container.publication or [])) {
            networks = [
              "tailscale"
            ];
          })
        ];
    };
  };
}
