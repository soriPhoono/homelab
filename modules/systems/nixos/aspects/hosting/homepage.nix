/**
  Homepage dashboard for the services this host runs.

  Tiles are read from the host's own Nix options instead of a docker socket:
  oci-containers published through docktail link to their tailnet name, and
  every user's rootless `services.podman` container with a published port
  links to that port on loopback. Nothing is mounted into homepage, and it
  holds no secrets.

  Local only: the module has no bind-address option, so HOSTNAME pins it to
  loopback and the closed firewall is the second layer.
*/
{
  den.aspects.hosting.homepage = {
    nixos =
      { config, lib, ... }:
      let
        inherit (config.networking) hostName;
        port = 8082;

        # Tiles are grouped by container name; anything unlisted lands in
        # "Services". Podman containers are always "Local".
        groupOf = {
          jellyfin = "Media";
          seerr = "Media";
          sonarr = "Automation";
          radarr = "Automation";
          lidarr = "Automation";
          prowlarr = "Automation";
          bookshelf = "Automation";
          qbittorrent = "Downloads";
        };
        groupOrder = [
          "Media"
          "Automation"
          "Downloads"
          "Local"
          "Services"
        ];
        # Icons default to the container name, which dashboard-icons covers
        # for the media stack.
        iconOf = {
          "9router" = "mdi-router-network";
        };

        # Named after the container (jellyfin), not its docktail name (media),
        # so groups and icons key on what the service is.
        dockerTiles = lib.concatLists (
          lib.mapAttrsToList (
            name: container:
            let
              labels = container.labels or { };
              tailnetName = labels."docktail.service.name" or null;
            in
            lib.optional ((labels."docktail.service.enable" or "false") == "true" && tailnetName != null) {
              inherit name;
              href = "http://${tailnetName}";
              group = groupOf.${name} or "Services";
              icon = iconOf.${name} or name;
            }
          ) config.virtualisation.oci-containers.containers
        );

        # "[ip:]host:container[/proto]" -> loopback URL of the host port.
        # UDP and unpublished ports have nothing to open in a browser.
        portUrl =
          spec:
          let
            parts = lib.splitString ":" (lib.head (lib.splitString "/" spec));
            ip = if lib.length parts == 3 then lib.head parts else "";
            bind = if ip == "" || ip == "0.0.0.0" then "127.0.0.1" else ip;
          in
          if lib.hasSuffix "/udp" spec || lib.length parts < 2 then
            null
          else
            "http://${bind}:${lib.elemAt parts (lib.length parts - 2)}";

        podmanTiles = lib.concatMap (
          user:
          lib.concatLists (
            lib.mapAttrsToList (
              name: container:
              let
                url = lib.findFirst (u: u != null) null (map portUrl container.ports);
              in
              lib.optional (url != null) {
                inherit name;
                href = url;
                group = "Local";
                icon = iconOf.${name} or name;
              }
            ) (user.services.podman.containers or { })
          )
        ) (lib.attrValues (config.home-manager.users or { }));

        tiles = dockerTiles ++ podmanTiles;
      in
      {
        services.homepage-dashboard = {
          enable = true;
          listenPort = port;
          allowedHosts = "127.0.0.1:${toString port},localhost:${toString port}";
          settings.title = hostName;
          services = lib.concatMap (
            group:
            let
              members = lib.sortOn (t: t.name) (lib.filter (t: t.group == group) tiles);
            in
            lib.optional (members != [ ]) {
              ${group} = map (t: {
                ${t.name} = {
                  inherit (t) href icon;
                  siteMonitor = t.href;
                };
              }) members;
            }
          ) groupOrder;
        };

        # Next.js binds to HOSTNAME, defaulting to every interface.
        systemd.services.homepage-dashboard.environment.HOSTNAME = "127.0.0.1";
      };
  };
}
