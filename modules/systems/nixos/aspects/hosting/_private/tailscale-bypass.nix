/**
  Keeps private subnets on the main routing table while a Tailscale exit node
  is active.

  The exit node is chosen at runtime (GUI or `tailscale set --exit-node`), so
  it never shows up in configuration. Once set, Tailscale's policy rule
  (priority 5270, table 52) captures container bridge subnets and the LAN.
  These `to <subnet> lookup main` rules sit ahead of it at priority 2500.
  'from' rules are intentionally omitted so outbound traffic from containers
  still leaves through the exit node.

  Imported by every container runtime aspect; NixOS deduplicates the import,
  so the watchdog is defined once however many runtimes a host enables.
*/
{
  lib,
  pkgs,
  config,
  ...
}:
let
  priority = toString 2500;
  subnets = [
    "172.16.0.0/12"
    "10.0.0.0/8"
    "192.168.0.0/16"
  ];
in
{
  config = lib.mkIf config.services.tailscale.enable {
    systemd.services.container-tailscale-bypass = {
      description = "Bypass Tailscale routing for private subnets (watchdog)";
      wants = [
        "network-online.target"
        "tailscaled.service"
      ];
      bindsTo = [ "tailscaled.service" ];
      after = [
        "network-online.target"
        "tailscaled.service"
      ];
      wantedBy = [
        "multi-user.target"
        "tailscaled.service"
      ];
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = 10;
        ExecStart = lib.getExe (
          pkgs.writeShellApplication {
            name = "container-tailscale-bypass-watchdog";
            runtimeInputs = with pkgs; [
              iproute2
              gnugrep
            ];
            text = ''
              apply_rules() {
                ${lib.concatMapStringsSep "\n" (subnet: ''
                  if ! ip rule show priority ${priority} | grep -q "to ${subnet} lookup main"; then
                    echo "Adding bypass rule to ${subnet}..."
                    ip rule add to ${subnet} lookup main prio ${priority}
                  fi
                '') subnets}
              }

              # Initial application — retry until rules persist
              for _ in $(seq 1 10); do
                apply_rules
                if ip rule show priority ${priority} | grep -q "to"; then
                  break
                fi
                sleep 3
              done

              # Watchdog loop: re-apply every 15s if tailscale wipes them
              while true; do
                sleep 15
                apply_rules
              done
            '';
          }
        );
        ExecStop = lib.getExe (
          pkgs.writeShellApplication {
            name = "container-tailscale-bypass-stop";
            runtimeInputs = with pkgs; [
              iproute2
              gnugrep
            ];
            text = lib.concatMapStringsSep "\n" (subnet: ''
              if ip rule show priority ${priority} | grep -q "to ${subnet} lookup main"; then
                echo "Removing bypass rule to ${subnet}..."
                ip rule del to ${subnet} lookup main prio ${priority}
              fi
            '') subnets;
          }
        );
      };
    };
  };
}
