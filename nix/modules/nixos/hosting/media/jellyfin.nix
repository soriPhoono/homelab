{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.hosting.media.jellyfin;
  # Tailscale Serve integration (HTTPS *.ts.net → localhost:8096); drives network.xml and Serve unit.
  tsServeActive = cfg.tailscaleServe.enable && config.core.networking.tailscale.enable;

  # NixOS services.tailscale.serve always emits svc:<name> (Tailscale *Services* — admin-defined VIPs).
  # For Jellyfin we need plain Serve on this node's MagicDNS name (*.ts.net); that is the CLI flow below.
  tailscaleExe = lib.getExe config.services.tailscale.package;
  js = config.services.jellyfin;
  # Jellyfin HTTP port (NixOS default). CLI must be `serve --yes --bg <port>` — do not put `--https=` between `--bg` and the port
  # or Tailscale returns "invalid argument format" (see journal on tailscale-serve-jellyfin).
  jellyfinServePort = "8096";

  # Align network.xml with Tailscale Serve: remote access + known proxies. Runs before every Jellyfin start.
  knownProxiesFragment = lib.optionalString tsServeActive ''
    if grep -Fq '<string>127.0.0.1</string>' "$cfg"; then
      :
    elif grep -Eq '<KnownProxies[[:space:]]*/>' "$cfg"; then
      ${pkgs.gnused}/bin/sed -i \
        's|<KnownProxies[[:space:]]*/>|<KnownProxies>\
      <string>127.0.0.1</string>\
      <string>[::1]</string>\
    </KnownProxies>|' "$cfg" \
        || true
    fi
  '';

  jellyfinNetworkXmlPre = pkgs.writeShellScript "jellyfin-network-xml-pre.sh" ''
    set -eu
    cfg="${js.configDir}/network.xml"
    want_remote="${
      if tsServeActive
      then "true"
      else "false"
    }"

    if [[ ! -f "$cfg" ]]; then
      exit 0
    fi

    # Dashboard "Allow remote connections" — required for tailnet clients via Serve + forwarded headers.
    if grep -q '<EnableRemoteAccess>' "$cfg"; then
      ${pkgs.gnused}/bin/sed -i \
        's|<EnableRemoteAccess>[^<]*</EnableRemoteAccess>|<EnableRemoteAccess>'"$want_remote"'</EnableRemoteAccess>|' \
        "$cfg" \
        || true
    fi

    ${knownProxiesFragment}

    chown ${js.user}:${js.group} "$cfg" 2>/dev/null || true
  '';

  tailscaleServeJellyfinStart = pkgs.writeShellScript "tailscale-serve-jellyfin-start.sh" ''
    set -euo pipefail
    export PATH="${
      lib.makeBinPath [
        pkgs.jq
        pkgs.coreutils
        pkgs.curl
      ]
    }"
    ts=${tailscaleExe}
    # Clear any stale Serve config so flags match what we enable below (Tailscale CLI 1.52+).
    "$ts" serve reset 2>/dev/null || true

    # Serve refuses until the backend is Running (activation can start this unit before login completes).
    for ((i = 0; i < 120; i++)); do
      state="$("$ts" status --json --peers=false | jq -r '.BackendState // empty')"
      if [[ "$state" == "Running" ]]; then
        break
      fi
      sleep 1
    done
    state="$("$ts" status --json --peers=false | jq -r '.BackendState // empty')"
    if [[ "$state" != "Running" ]]; then
      echo "tailscale-serve-jellyfin: Tailscale BackendState is '$state' (need Running). Try: tailscale up" >&2
      exit 1
    fi

    # Jellyfin must respond on loopback before Serve proxies (Ordering: After=jellyfin.service).
    # HTTP probe: first boot / DB migration can exceed 120s; cap stays within TimeoutStartSec.
    for ((i = 0; i < 300; i++)); do
      if curl -sS --connect-timeout 1 --max-time 3 -o /dev/null "http://127.0.0.1:8096/" 2>/dev/null; then
        break
      fi
      if [[ "$i" -eq 299 ]]; then
        echo "tailscale-serve-jellyfin: Jellyfin did not respond on http://127.0.0.1:8096/ within ~300s (see: journalctl -u jellyfin.service -b)" >&2
        exit 1
      fi
      sleep 1
    done

    # Default mode is HTTPS on 443. `--bg` must be immediately before the port (or use http://127.0.0.1:PORT).
    # Do not `exec`: need exit status for Type=oneshot.
    set +e
    out="$("$ts" serve --yes --bg ${jellyfinServePort} 2>&1)"
    rc=$?
    set -e
    if [[ "$rc" -ne 0 ]]; then
      echo "tailscale-serve-jellyfin: tailscale serve failed (exit $rc): $out" >&2
      exit "$rc"
    fi
  '';
  tailscaleServeJellyfinStop = pkgs.writeShellScript "tailscale-serve-jellyfin-stop.sh" ''
    set -euo pipefail
    # Matches `tailscale serve` hint: disable HTTPS listener on 443 for this node.
    ${tailscaleExe} serve --yes --https=443 off 2>/dev/null || true
  '';
in
  with lib; {
    options.hosting.media.jellyfin = {
      enable = mkEnableOption "Enable Jellyfin media server for edge device media archiving";
      acceleration.enable = mkEnableOption "Enable hardware acceleration (VAAPI) on the integrated GPU";
      tailscaleServe.enable = mkEnableOption ''
        Expose Jellyfin on your tailnet using Tailscale Serve on **this machine's** HTTPS URL (shown when Serve starts:
        `https://<machine>.<tailnet>.ts.net`, often also reachable via your short MagicDNS name).

        Implemented with `tailscale serve --yes --bg 8096` (plain Serve on the node; not NixOS
        `services.tailscale.serve`, whose `svc:…` keys target Tailscale **Services**, not MagicDNS).

        On each start, a privileged **ExecStartPre** updates `network.xml`: sets **Allow remote connections**
        (`<EnableRemoteAccess>`) to **on** while this integration is active and **off** when it is not, and when Serve is
        enabled expands the default empty `<KnownProxies />` to **127.0.0.1** and **[::1]** so Jellyfin trusts forwarded
        headers from Serve. If you already customized Known proxies, add those addresses manually (see
        [Jellyfin reverse proxy](https://jellyfin.org/docs/general/post-install/networking/reverse-proxy/)).
      '';

      tailscaleServe.publishedServerUrl = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          HTTPS origin clients should use (no trailing slash), e.g.
          `https://your-host.your-tailnet.ts.net`. Passed to Jellyfin as `JELLYFIN_PublishedServerUrl` so the web UI and
          discovery stop advertising loopback/LAN-only URLs behind Tailscale Serve (fixes “unable to find server”).

          Defaults to `core.networking.tailscale.serve.tailnetOrigin` when that option is set.
        '';
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        hosting.media.jellyfin.tailscaleServe.publishedServerUrl =
          mkDefault config.core.networking.tailscale.serve.tailnetOrigin;

        services.jellyfin.enable = true;

        systemd.services.jellyfin.serviceConfig = {
          ExecStartPre = [
            "+${jellyfinNetworkXmlPre}"
          ];
          ProtectSystem = lib.mkForce "strict";
          ProtectHome = lib.mkForce true;
          StateDirectory = "jellyfin";
          CacheDirectory = "jellyfin";
          ReadWritePaths = ["/mnt/local/media"];
        };
      }
      (mkIf cfg.acceleration.enable {
        services.jellyfin = {
          forceEncodingConfig = true;
          hardwareAcceleration = {
            enable = true;
            device = "/dev/dri/renderD128";
            type =
              if config.core.hardware.gpu.intel.integrated.enable
              then "qsv"
              else "vaapi";
          };
          transcoding = {
            enableHardwareEncoding = true;
            enableIntelLowPowerEncoding = config.core.hardware.gpu.intel.integrated.enable;
            throttleTranscoding = false;
            hardwareEncodingCodecs.hevc = true;
            hardwareDecodingCodecs = {
              h264 = true;
              hevc = true;
            };
          };
        };

        # Ensure the jellyfin user has access to graphics hardware
        users = {
          groups.media.members = ["jellyfin"];
          users.jellyfin = {
            extraGroups = [
              "video"
              "render"
            ];
          };
        };
      })
      (mkIf (cfg.tailscaleServe.enable && config.core.networking.tailscale.enable) {
        systemd.services = {
          tailscale-serve-jellyfin = {
            description = "Tailscale Serve HTTPS for Jellyfin (node MagicDNS / *.ts.net)";
            after = [
              "tailscaled.service"
              "tailscaled-autoconnect.service"
              "jellyfin.service"
            ];
            wants = [
              "tailscaled.service"
              "jellyfin.service"
            ];
            wantedBy = ["multi-user.target"];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              Restart = "on-failure";
              RestartSec = "5s";
              # tailscaled wait (120s) + Jellyfin HTTP probe (≈120–240s worst case) + serve CLI.
              TimeoutStartSec = "600s";
              ExecStart = "${tailscaleServeJellyfinStart}";
              ExecStop = "${tailscaleServeJellyfinStop}";
            };
          };
        };
      })
      (
        mkIf
        (
          cfg.tailscaleServe.enable
          && config.core.networking.tailscale.enable
          && cfg.tailscaleServe.publishedServerUrl != null
        )
        {
          systemd.services.jellyfin.environment = {
            JELLYFIN_PublishedServerUrl = lib.removeSuffix "/" cfg.tailscaleServe.publishedServerUrl;
          };
        }
      )
    ]);
  }
