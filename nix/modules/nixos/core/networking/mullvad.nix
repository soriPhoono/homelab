{
  lib,
  config,
  ...
}: let
  cfg = config.core.networking.mullvad;

  inherit (lib) concatStringsSep optional optionalString;

  # Mullvad split-tunnel marks (see https://mullvad.net/en/help/split-tunneling-with-linux-advanced )
  ctMark = "0x00000f41";
  metaMark = "0x6d6f6c65";

  tailscaleIpv4 = "100.64.0.0/10";
  tailscaleIpv6 = "fd7a:115c:a1e0::/48";

  overlayIpv4 = optional cfg.excludeTailscaleIpv4 tailscaleIpv4;
  overlayIpv6 = optional cfg.excludeTailscaleIpv6 tailscaleIpv6;

  hostIpv4 = overlayIpv4 ++ cfg.localIpv4Subnets ++ cfg.extraIpv4Subnets;
  hostIpv6 = overlayIpv6 ++ cfg.extraIpv6Subnets;

  dockerIpv4 =
    if cfg.excludeDocker.enable
    then cfg.excludeDocker.ipv4Subnets
    else [];

  # Destinations the host may talk to (overlay, LAN, and Docker bridges when Docker bypass is on)
  outputIpv4 = lib.unique (hostIpv4 ++ dockerIpv4);
  outputIpv6 = lib.unique hostIpv6;

  commaJoin = parts: concatStringsSep ",\n    " parts;

  ipv4Define = optionalString (outputIpv4 != []) ''
    define EXCLUDED_IPV4 = {
        ${commaJoin outputIpv4}
    }
  '';

  ipv6Define = optionalString (outputIpv6 != []) ''
    define EXCLUDED_IPV6 = {
        ${commaJoin outputIpv6}
    }
  '';

  dockerDefine = optionalString (dockerIpv4 != []) ''
    define DOCKER_IPV4 = {
        ${commaJoin dockerIpv4}
    }
  '';

  nftTableContent = ''
    ${ipv4Define}
    ${ipv6Define}
    ${dockerDefine}
    # Runs before Mullvad route-output chain at priority 0 so packets are marked first
    # (rules loaded at boot can precede table inet mullvad; see mullvadvpn-app#5418).
    chain excludeOutgoing {
      type route hook output priority -100; policy accept;
      ${optionalString (outputIpv4 != []) ''
      ip daddr $EXCLUDED_IPV4 ct mark set ${ctMark} meta mark set ${metaMark};
    ''}
      ${optionalString (outputIpv6 != []) ''
      ip6 daddr $EXCLUDED_IPV6 ct mark set ${ctMark} meta mark set ${metaMark};
    ''}
    }
    ${optionalString (cfg.excludeDocker.enable && dockerIpv4 != []) ''
      chain excludeForwarding {
        type filter hook prerouting priority -150; policy accept;
        ip saddr $DOCKER_IPV4 ct mark set ${ctMark} meta mark set ${metaMark};
      }
    ''}
  '';

  hasNftRules =
    (outputIpv4 != [])
    || (outputIpv6 != [])
    || (cfg.excludeDocker.enable && dockerIpv4 != []);

  mullvadPkg = config.services.mullvad-vpn.package;
in
  with lib; {
    options.core.networking.mullvad = {
      enable = mkEnableOption ''
        Mullvad VPN (services.mullvad-vpn) with nftables exclusions so overlay
        (Tailscale / NetBird-style CGNAT), local LAN segments, and optionally Docker
        bridge traffic can bypass the tunnel while other traffic uses Mullvad.
        See {option}`relaxReversePathFilter` when clearnet breaks but overlays work.
      '';

      excludeTailscaleIpv4 = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Exclude IPv4 CGNAT 100.64.0.0/10 from the Mullvad tunnel (Tailscale-style
          peers and typical NetBird peer addresses such as 100.125.x.x).
        '';
      };

      excludeTailscaleIpv6 = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Exclude Tailscale IPv6 ULA fd7a:115c:a1e0::/48 from the Mullvad tunnel.
          NetBird IPv6 overlays use per-network prefixes; add those via
          {option}`extraIpv6Subnets` instead of a fixed default.
        '';
      };

      localIpv4Subnets = mkOption {
        type = types.listOf types.str;
        default = ["192.168.0.0/16"];
        example = ["192.168.1.0/24" "10.0.0.0/24"];
        description = ''
          IPv4 prefixes to mark for split routing alongside Mullvad (typical home LAN
          is 192.168.x.0/24; the default /16 matches Mullvad own LAN handling and
          avoids unmarked traffic to e.g. 192.168.1.0/24 being steered into the VPN
          routing table). Override with a tighter list if you prefer. Set to `[]`
          to omit LAN defaults.
        '';
      };

      extraIpv4Subnets = mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["10.50.0.0/16"];
        description = "Extra IPv4 CIDRs to exclude from the Mullvad tunnel.";
      };

      extraIpv6Subnets = mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["fd00:dead:beef::/64"];
        description = ''
          Extra IPv6 prefixes to exclude (e.g. NetBird overlay /64 from your
          management server or `ip -6 route` once connected).
        '';
      };

      excludeDocker = {
        enable = mkEnableOption ''
          nftables rules so traffic sourced from Docker IPv4 bridge pools is
          marked for Mullvad exclusion (clearnet from containers). Disabled by
          default to avoid surprising non-VPN container egress on servers.
        '';

        ipv4Subnets = mkOption {
          type = types.listOf types.str;
          default = ["172.16.0.0/12"];
          description = ''
            IPv4 CIDRs for Docker bridges (default covers docker0 and typical
            user-defined bridges). Extend if you use custom bridge subnets.
            See Mullvad discussion on forwarded traffic:
            https://github.com/mullvad/mullvadvpn-app/issues/4814
          '';
        };
      };

      allowLocalNetwork = mkEnableOption ''
        Run `mullvad lan set allow` after the daemon starts so RFC1918-style
        traffic can bypass the tunnel (e.g. Tailscale subnet routes). Broadens
        non-tunnel traffic beyond the explicit nft excludes; overlaps with
        {option}`localIpv4Subnets` is harmless.
      '';

      disableLockdownMode = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Run `mullvad lockdown-mode set off` once the CLI is available.
          Lockdown mode can leave the system with no usable connectivity when
          combined with firewall ordering; disabling it matches typical desktop
          expectations (toggle in app if you want strict blocking when
          disconnected).
        '';
      };

      relaxReversePathFilter = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Set {option}`networking.firewall.checkReversePath` to false (via
          `lib.mkDefault`) so NixOS nftables `rpfilter` does not drop legitimate
          traffic when Mullvad policy routing and marked split-tunnel paths disagree
          with strict reverse-path checks (common symptom: overlay works, clearnet
          does not). Set to false if you need strict RPF and accept tuning rules
          yourself.
        '';
      };

      setDefaultDns = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Run `mullvad dns set default` so the daemon uses Mullvad DNS on the
          tunnel (allowed by `inet mullvad` rules). Without this, the app rejects
          outbound UDP/TCP destination port 53 to most addresses before LAN-friendly
          rules apply, which breaks {command}`systemd-resolved` when it forwards to
          the router or public resolvers on port 53 (name lookup fails even though
          `ip route get 1.1.1.1` uses `wg0-mullvad`). Set false if you rely on
          {command}`mullvad dns set custom` or DNS over TLS on non-53 ports.
        '';
      };
    };

    config = lib.mkIf cfg.enable (lib.mkMerge [
      {
        # Must match services.mullvad-vpn (daemon); pkgs.mullvad-vpn can be a
        # different version than services.mullvad-vpn.package (e.g. mullvad vs
        # mullvad-vpn attrs), which breaks `mullvad status` gRPC parsing.
        environment.systemPackages = [mullvadPkg];

        services.mullvad-vpn.enable = true;

        networking = {
          firewall.checkReversePath = lib.mkIf cfg.relaxReversePathFilter (lib.mkDefault false);
        };

        networking.nftables.tables.mullvad_overlay_exclude = lib.mkIf hasNftRules {
          family = "inet";
          content = nftTableContent;
        };
      }
      (mkIf config.core.networking.network-manager.enable {
        networking.networkmanager.unmanaged = ["wg0-mullvad"];
      })
      (mkIf (cfg.allowLocalNetwork || cfg.disableLockdownMode || cfg.setDefaultDns) {
        systemd.services.mullvad-cli-bootstrap = {
          description = "Apply Mullvad CLI settings (DNS, lockdown, LAN) after daemon start";
          wantedBy = ["multi-user.target"];
          after = ["mullvad-daemon.service"];
          wants = ["mullvad-daemon.service"];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            set -euo pipefail
            mullvad="${mullvadPkg}/bin/mullvad"
            for _ in $(seq 1 30); do
              if ${optionalString cfg.setDefaultDns ''
              "$mullvad" dns set default &&
            ''}${optionalString cfg.disableLockdownMode ''
              "$mullvad" lockdown-mode set off &&
            ''}${optionalString cfg.allowLocalNetwork ''
              "$mullvad" lan set allow &&
            ''}true; then
                exit 0
              fi
              sleep 1
            done
            echo "mullvad-cli-bootstrap: Mullvad CLI not ready after 30 attempts" >&2
            exit 1
          '';
        };
      })
    ]);
  }
