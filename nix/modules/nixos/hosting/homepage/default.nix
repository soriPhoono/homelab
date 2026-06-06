{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.homepage;
  inherit
    (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    mapAttrsToList
    filterAttrs
    optionalAttrs
    ;

  # ── Proxy & DNS helpers ──────────────────────────
  proxyCfg = config.hosting.proxy;
  dnsCfg = proxyCfg.dns;

  rootDomain =
    if dnsCfg.localSubdomain != ""
    then "${dnsCfg.localSubdomain}.${dnsCfg.baseDomain}"
    else dnsCfg.baseDomain;

  # All proxy services except the homepage itself
  services = filterAttrs (name: _: name != "default") proxyCfg.services;

  # ── Font Awesome icon mapping ────────────────────
  getFaIcon = name:
    builtins.getAttr name {
      media = "fas fa-film";
      movies = "fas fa-film";
      shows = "fas fa-tv";
      watch = "fas fa-play-circle";
      downloads = "fas fa-download";
      seerr = "fas fa-ticket-alt";
      sonarr = "fas fa-tv";
      radarr = "fas fa-film";
      prowlarr = "fas fa-search";
      flaresolverr = "fas fa-shield-alt";
      qbittorrent = "fas fa-bolt";
      jellyfin = "fas fa-play-circle";
      hermes = "fas fa-robot";
      ai = "fas fa-brain";
      proxy = "fas fa-network-wired";
      platform = "fas fa-cubes";
      docker = "fab fa-docker";
      homepage = "fas fa-home";
      git = "fab fa-git-alt";
      ci = "fas fa-rotate";
      monitor = "fas fa-chart-line";
      metrics = "fas fa-chart-bar";
      logs = "fas fa-file-alt";
      storage = "fas fa-database";
      backup = "fas fa-archive";
      vault = "fas fa-vault";
      auth = "fas fa-lock";
      mail = "fas fa-envelope";
      chat = "fas fa-comments";
      wiki = "fas fa-book";
      notes = "fas fa-sticky-note";
      dashboard = "fas fa-tachometer-alt";
      default = "fas fa-server";
    };

  # ── Homer settings builder ──────────────────────

  # Build a Homer service group from each proxy service
  mkServiceGroup = name: svc: let
    mainItem = {
      inherit (svc) name;
      subtitle = svc.description or "";
      url = "https://${name}.${rootDomain}";
      target = "_blank";
    };

    extItems =
      mapAttrsToList
      (
        path: sub: {
          inherit (sub) name;
          subtitle = sub.description or "";
          url = "https://${name}.${rootDomain}${path}";
          target = "_blank";
        }
      )
      (svc.extraPaths or {});

    items =
      if extItems == []
      then [mainItem]
      else [mainItem] ++ extItems;
  in {
    inherit (svc) name;
    icon = getFaIcon name;
    inherit items;
  };
in {
  options.hosting.homepage = {
    enable = mkEnableOption ''
      a Homer-based homepage dashboard for the hosting system.

      Automatically populates services.homer.settings from
      hosting.proxy.services. Each proxy service becomes a Homer service
      group with items for the main service and its extraPaths.

      You still need to serve the dashboard — either by enabling
      services.homer.virtualHost.caddy or by adding a hosting.proxy.services
      entry pointing to your web server of choice.
    '';

    title = mkOption {
      type = types.str;
      default = "Homelab";
      description = "Browser tab title for the dashboard";
    };

    subtitle = mkOption {
      type = types.str;
      default = "Self-hosted services";
      description = "Subtitle displayed below the heading";
    };

    header = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to show the header section";
    };

    footer = mkOption {
      type = types.either types.bool types.str;
      default = false;
      description = ''
        Footer HTML content or false to hide.
        Set to a string (e.g. "<p>Powered by NixOS</p>") to show a custom footer.
      '';
    };

    columns = mkOption {
      type = types.str;
      default = "3";
      description = ''
        Number of columns for the service grid. Must be a factor of 12
        (1, 2, 3, 4, 6, 12) or "auto".
      '';
    };

    theme = mkOption {
      type = types.str;
      default = "default";
      description = "Homer theme name";
    };

    links = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "Link label";
            };
            icon = mkOption {
              type = types.str;
              description = "Font Awesome icon class (e.g. 'fab fa-github')";
            };
            url = mkOption {
              type = types.str;
              description = "Link URL";
            };
            target = mkOption {
              type = types.str;
              default = "_blank";
              description = "Link target attribute";
            };
          };
        }
      );
      default = [];
      description = "Navbar links displayed at the top of the dashboard";
      example = [
        {
          name = "GitHub";
          icon = "fab fa-github";
          url = "https://github.com";
        }
      ];
    };
  };

  config = mkIf cfg.enable {
    # Populate the upstream Homer module with our auto-generated settings
    services.homer = {
      enable = true;
      settings =
        {
          inherit (cfg) title;
          inherit (cfg) subtitle;
          inherit (cfg) header;
          inherit (cfg) footer;
          inherit (cfg) columns;
          connectivityCheck = true;
          inherit (cfg) theme;

          defaults = {
            layout = "columns";
            colorTheme = "auto";
          };
        }
        // optionalAttrs (cfg.links != []) {inherit (cfg) links;}
        // optionalAttrs (services != {}) {services = mapAttrsToList mkServiceGroup services;};
    };
  };
}
