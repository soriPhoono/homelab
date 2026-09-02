{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib) mkMerge;
  inherit (lib.homelab.containers) mkContainer mkContainerOption;

  name = "grafana";
  cfg = config.hosting.monitoring.${name};
  configurationDirectory = "/var/lib/${name}";
  privateNetwork = "${name}-internal";
  prometheusName = "${name}-prometheus";
  lokiName = "${name}-loki";
  alloyName = "${name}-alloy";
  nodeExporterName = "${name}-node-exporter";
  cadvisorName = "${name}-cadvisor";
  internalCfg =
    cfg
    // {
      container = cfg.container // {publication = [];};
    };

  datasourceConfig = pkgs.writeText "grafana-datasources.yaml" ''
    apiVersion: 1
    datasources:
      - name: Prometheus
        type: prometheus
        access: proxy
        url: http://${prometheusName}:9090
        isDefault: true
        jsonData:
          httpMethod: POST
          manageAlerts: true
          prometheusType: Prometheus
      - name: Loki
        type: loki
        access: proxy
        url: http://${lokiName}:3100
        jsonData:
          maxLines: 1000
  '';

  prometheusConfig = pkgs.writeText "prometheus.yml" ''
    global:
      scrape_interval: ${cfg.scrapeInterval}
      evaluation_interval: ${cfg.scrapeInterval}

    scrape_configs:
      - job_name: prometheus
        static_configs:
          - targets: ["${prometheusName}:9090"]
      - job_name: node
        static_configs:
          - targets: ["${nodeExporterName}:9100"]
      - job_name: containers
        static_configs:
          - targets: ["${cadvisorName}:8080"]
    ${cfg.extraScrapeConfigs}
  '';

  lokiConfig = pkgs.writeText "loki-config.yaml" ''
    auth_enabled: false

    server:
      http_listen_port: 3100

    common:
      path_prefix: /loki
      storage:
        filesystem:
          chunks_directory: /loki/chunks
          rules_directory: /loki/rules
      replication_factor: 1
      ring:
        kvstore:
          store: inmemory

    schema_config:
      configs:
        - from: 2024-01-01
          store: tsdb
          object_store: filesystem
          schema: v13
          index:
            prefix: index_
            period: 24h

    analytics:
      reporting_enabled: false
  '';

  alloyConfig = pkgs.writeText "config.alloy" ''
    discovery.docker "containers" {
      host = "unix:///var/run/docker.sock"
    }

    loki.source.docker "containers" {
      host = "unix:///var/run/docker.sock"
      targets = discovery.docker.containers.targets
      forward_to = [loki.write.default.receiver]
    }

    loki.write "default" {
      endpoint {
        url = "http://${lokiName}:3100/loki/api/v1/push"
      }
    }
  '';

  mkInternalContainer = {
    containerName,
    image,
  }:
    mkMerge [
      (mkContainer {
        name = containerName;
        inherit config image;
        cfg = internalCfg;
      })
      {
        networks = [privateNetwork];
      }
    ];
in
  with lib; {
    options.hosting.monitoring.${name} =
      (mkContainerOption {
        inherit name;
        description = "Grafana metrics and log monitoring suite";
      })
      // {
        url = mkOption {
          type = types.str;
          default = "https://${config.networking.hostName}-monitoring.xerus-augmented.ts.net";
          description = "URL at which Grafana is served.";
        };

        adminUser = mkOption {
          type = types.str;
          default = "admin";
          description = "Initial Grafana administrator username.";
        };

        adminPasswordSecret = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            Optional SOPS secret containing Grafana's initial administrator password.
            When unset, Grafana's upstream default password behavior is used.
          '';
        };

        scrapeInterval = mkOption {
          type = types.str;
          default = "15s";
          description = "Interval at which Prometheus scrapes exporters.";
        };

        extraScrapeConfigs = mkOption {
          type = types.lines;
          default = "";
          description = ''
            Additional YAML scrape configurations appended to Prometheus's
            scrape_configs list.
          '';
        };
      };

    config = mkIf cfg.enable (mkMerge [
      {
        hosting.enable = true;

        assertions = [
          {
            assertion = config.hosting.platforms.docker.enable;
            message = "grafana requires the Docker hosting platform to be enabled.";
          }
        ];

        systemd.tmpfiles.rules = [
          "d ${configurationDirectory} 0750 root root -"
          "d ${configurationDirectory}/grafana 0750 472 472 -"
          "d ${configurationDirectory}/prometheus 0750 65534 65534 -"
          "d ${configurationDirectory}/loki 0750 10001 10001 -"
          "d ${configurationDirectory}/alloy 0750 root root -"
        ];

        sops.secrets = mkIf (cfg.adminPasswordSecret != null) {
          ${cfg.adminPasswordSecret} = {};
        };

        sops.templates = mkIf (cfg.adminPasswordSecret != null) {
          "hosting/monitoring/grafana.env".content = ''
            GF_SECURITY_ADMIN_PASSWORD=${config.sops.placeholder.${cfg.adminPasswordSecret}}
          '';
        };

        virtualisation.oci-containers.containers = {
          ${name} = mkMerge [
            (mkContainer {
              inherit name cfg config;
              image = "grafana/grafana:13.0.8";
              serviceName = "monitoring";
              servicePort = 3000;
              homepage = {
                group = "Monitoring";
                name = "Grafana";
                icon = "grafana.png";
                description = "Metrics and log monitoring";
                serviceName = "monitoring";
              };
            })
            {
              user = "472:472";
              dependsOn = [prometheusName lokiName];
              environment = {
                GF_ANALYTICS_CHECK_FOR_PLUGIN_UPDATES = "false";
                GF_ANALYTICS_CHECK_FOR_UPDATES = "false";
                GF_ANALYTICS_REPORTING_ENABLED = "false";
                GF_AUTH_ANONYMOUS_ENABLED = "false";
                GF_SECURITY_ADMIN_USER = cfg.adminUser;
                GF_SERVER_DOMAIN = removePrefix "https://" (removePrefix "http://" cfg.url);
                GF_SERVER_ROOT_URL = cfg.url;
                GF_USERS_ALLOW_SIGN_UP = "false";
                TZ = config.time.timeZone;
              };
              environmentFiles = optional (cfg.adminPasswordSecret != null) config.sops.templates."hosting/monitoring/grafana.env".path;
              networks = [privateNetwork];
              volumes = [
                "${configurationDirectory}/grafana:/var/lib/grafana"
                "${datasourceConfig}:/etc/grafana/provisioning/datasources/datasources.yaml:ro"
              ];
            }
          ];

          ${prometheusName} = mkMerge [
            (mkInternalContainer {
              containerName = prometheusName;
              image = "prom/prometheus:v3.6.0";
            })
            {
              user = "65534:65534";
              dependsOn = [nodeExporterName cadvisorName];
              cmd = [
                "--config.file=/etc/prometheus/prometheus.yml"
                "--storage.tsdb.path=/prometheus"
                "--storage.tsdb.retention.time=30d"
              ];
              volumes = [
                "${configurationDirectory}/prometheus:/prometheus"
                "${prometheusConfig}:/etc/prometheus/prometheus.yml:ro"
              ];
            }
          ];

          ${lokiName} = mkMerge [
            (mkInternalContainer {
              containerName = lokiName;
              image = "grafana/loki:3.6.0";
            })
            {
              user = "10001:10001";
              cmd = ["-config.file=/etc/loki/config.yaml"];
              volumes = [
                "${configurationDirectory}/loki:/loki"
                "${lokiConfig}:/etc/loki/config.yaml:ro"
              ];
            }
          ];

          ${alloyName} = mkMerge [
            (mkInternalContainer {
              containerName = alloyName;
              image = "grafana/alloy:v1.19.2";
            })
            {
              dependsOn = [lokiName];
              cmd = [
                "run"
                "--server.http.listen-addr=0.0.0.0:12345"
                "--storage.path=/var/lib/alloy/data"
                "/etc/alloy/config.alloy"
              ];
              volumes = [
                "${configurationDirectory}/alloy:/var/lib/alloy/data"
                "${alloyConfig}:/etc/alloy/config.alloy:ro"
                "/var/run/docker.sock:/var/run/docker.sock:ro"
              ];
            }
          ];

          ${nodeExporterName} = mkMerge [
            (mkInternalContainer {
              containerName = nodeExporterName;
              image = "prom/node-exporter:v1.9.1";
            })
            {
              user = "0:0";
              cmd = [
                "--path.procfs=/host/proc"
                "--path.sysfs=/host/sys"
                "--path.rootfs=/host"
              ];
              volumes = [
                "/proc:/host/proc:ro"
                "/sys:/host/sys:ro"
                "/:/host:ro,rslave"
              ];
            }
          ];

          ${cadvisorName} = mkMerge [
            (mkInternalContainer {
              containerName = cadvisorName;
              image = "ghcr.io/google/cadvisor:v0.56.0";
            })
            {
              privileged = true;
              extraOptions = ["--device=/dev/kmsg:/dev/kmsg"];
              volumes = [
                "/:/rootfs:ro"
                "/var/run:/var/run:ro"
                "/sys:/sys:ro"
                "/var/lib/docker:/var/lib/docker:ro"
                "/dev/disk:/dev/disk:ro"
              ];
            }
          ];
        };
      }
    ]);
  }
