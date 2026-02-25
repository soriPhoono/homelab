{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.core.clamav;
in {
  options.core.clamav = {
    enable = mkEnableOption "ClamAV antivirus daemon, updater, scanner, fangfrisch, and on-access scanner";

    scanDirectories = mkOption {
      type = with types; listOf str;
      default = [
        "/home"
        "/root"
        "/tmp"
        "/etc"
        "/var/lib"
      ];
      description = "Directories to scan periodically with the ClamAV scanner.";
      example = ["/home" "/srv"];
    };

    scanInterval = mkOption {
      type = types.str;
      default = "*-*-* 04:00:00";
      description = "Systemd calendar expression for how often the scanner runs.";
      example = "daily";
    };

    updaterInterval = mkOption {
      type = types.str;
      default = "hourly";
      description = "Systemd calendar expression for how often freshclam runs.";
    };

    updaterFrequency = mkOption {
      type = types.int;
      default = 24;
      description = "Number of database checks per day (used by freshclam).";
    };

    fangfrischInterval = mkOption {
      type = types.str;
      default = "hourly";
      description = "Systemd calendar expression for how often fangfrisch runs.";
    };

    onAccessPaths = mkOption {
      type = with types; listOf str;
      default = flatten (mapAttrsToList (_name: user: builtins.attrValues (filterAttrs (_name: value: builtins.isString value && hasPrefix "/" value) user.xdg.userDirs)) config.home-manager.users);
      description = "Paths for clamonacc on-access scanning.";
      example = ["/home" "/srv"];
    };

    onAccessPrevention = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether clamonacc blocks file access until scanning completes.
        Set to true for stricter security (may impact performance).
      '';
    };
  };

  config = mkIf cfg.enable {
    services.clamav = {
      # ── Daemon (clamd) ────────────────────────────────────────────────────
      daemon = {
        enable = true;
        settings = {
          # Logging
          LogFile = "/var/log/clamav/clamd.log";
          LogFileMaxSize = 0;
          LogTime = true;
          LogClean = false;
          LogSyslog = false;

          # PID / socket / database
          PidFile = "/run/clamav/clamd.pid";
          DatabaseDirectory = "/var/lib/clamav";
          LocalSocket = "/run/clamav/clamd.ctl";
          FixStaleSocket = true;

          # TCP (localhost only, matching the gist)
          TCPSocket = 3310;
          TCPAddr = "127.0.0.1";

          # On-access paths (clamonacc uses daemon settings)
          OnAccessIncludePath = cfg.onAccessPaths;
          OnAccessPrevention = cfg.onAccessPrevention;
        };
      };

      # ── Updater (freshclam) ───────────────────────────────────────────────
      updater = {
        enable = true;
        interval = cfg.updaterInterval;
        frequency = cfg.updaterFrequency;
        settings = {
          DatabaseDirectory = "/var/lib/clamav";
          UpdateLogFile = "/var/log/clamav/freshclam.log";
          LogFileMaxSize = 0;
          LogTime = true;
          LogSyslog = false;
          PidFile = "/run/clamav/freshclam.pid";
          DatabaseOwner = "clamav";
          Checks = cfg.updaterFrequency;
          DNSDatabaseInfo = "current.cvd.clamav.net";
          DatabaseMirror = [
            "database.clamav.net"
          ];
        };
      };

      # ── Scanner (clamdscan on a timer) ────────────────────────────────────
      scanner = {
        enable = true;
        interval = cfg.scanInterval;
        inherit (cfg) scanDirectories;
      };

      # ── Fangfrisch (third-party signature updater) ────────────────────────
      fangfrisch = {
        enable = true;
        interval = cfg.fangfrischInterval;
        # urlhaus and sanesecurity are enabled by default upstream.
        # Override here if you need to tweak specific sources.
        settings = {};
      };

      # ── On-access scanner (clamonacc) ─────────────────────────────────────
      clamonacc.enable = true;
    };

    # ── Systemd Configuration (Logging, PIDs, Sockets, and Notifications) ──
    systemd = {
      tmpfiles.rules = [
        "d /var/log/clamav 0750 clamav clamav -"
        "d /run/clamav 0755 clamav clamav -"
        "d /var/lib/clamav 0755 clamav clamav -"
      ];

      services = let
        serviceConfig = {
          RuntimeDirectory = "clamav";
          RuntimeDirectoryMode = "0755";
          LogsDirectory = "clamav";
          LogsDirectoryMode = "0750";
          StateDirectory = "clamav";
          StateDirectoryMode = "0755";
        };
      in {
        clamav-daemon = {
          inherit serviceConfig;
        };
        clamav-freshclam = {
          inherit serviceConfig;
        };
      };
    };
  };
}
