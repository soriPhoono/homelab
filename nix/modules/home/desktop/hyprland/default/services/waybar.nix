{
  lib,
  pkgs,
  config,
  nixosConfig,
  ...
}: let
  cfg = config.desktop.hyprland.default;
in
  with lib; {
    config = mkIf cfg.enable {
      stylix.targets.waybar.enable = false;

      programs.waybar = {
        enable = true;

        settings = {
          mainBar = {
            layer = "top";
            position = "top";
            height = 46;
            output = [
              "eDP-1"
            ];

            modules-left = [
              "hyprland/workspaces"
              "custom/separator"
              "cpu"
              "memory"
              "custom/spacer"
            ];
            modules-center = [
              "mpris"
            ];
            modules-right = [
              "custom/separator"
              "network"
              "bluetooth"
              "wireplumber"
              "battery"
              "backlight"
            ];

            "hyprland/workspaces" = {
              format = "{icon}";
              format-window-separator = "";

              show-special = true;
              special-visible-only = true;

              sort-by = "number";

              format-icons = {
                default = "";
                empty = "";
                active = "";
                urgent = "";
              };

              persistent-workspaces = {
                "*" = 6;
              };
            };

            cpu = {
              format = "{usage}% ";
              interval = 1;
              states = {
                medium = 50;
                high = 80;
                danger = 90;
              };
            };

            memory = {
              format = "{percentage}% ";
              interval = 1;
              states = {
                medium = 50;
                high = 80;
                danger = 90;
              };
            };

            mpris = {
              format = "{status_icon} {dynamic}";
              interval = 1;

              status-icons = {
                playing = " ▶";
                paused = " 󰏤";
                stopped = " 󰓛";
              };

              dynamic-len = 25;
            };

            network = {
              interval = 1;

              format-wifi = "{icon}";
              format-ethernet = "<span color='#a6da95'>󰈀</span>";
              format-disconnected = "<span color='#ed8796'>󰖪</span>";
              format-disabled = "<span color='#363a4f'>󰖪</span>";
              format-icons = [
                "<span color='#ed8796'>󰤭</span>"
                "<span color='#f5a97f'>󰤯</span>"
                "<span color='#f5a97f'>󰤟</span>"
                "<span color='#eed49f'>󰤢</span>"
                "<span color='#eed49f'>󰤥</span>"
                "<span color='#a6da95'>󰤨</span>"
              ];

              tooltip-format-wifi = "Connected (WiFi): {essid} @{frequency}GHz\nIP: {ipaddr}\nSignal: {signalStrength}%\nUp: {bandwidthUpBytes}\nDown: {bandwidthDownBytes}";
              tooltip-format-ethernet = "Connected (Ethernet): {essid} @{frequency}GHz\nIP: {ipaddr}\nUp: {bandwidthUpBytes}\nDown: {bandwidthDownBytes}";
              tooltip-format-disconnected = "No Connection";
              tooltip-format-disabled = "WiFi Disabled";

              on-click = "${pkgs.networkmanagerapplet}/bin/nm-connection-editor";
              on-click-right = let
                networkToggleScript = pkgs.writeShellApplication {
                  name = "toggle-network";
                  runtimeInputs = [
                    pkgs.networkmanagerapplet
                  ];
                  text = ''
                    if [[ $(nmcli radio wifi) == 'enabled' ]]; then
                      nmcli radio wifi off
                    else
                      nmcli radio wifi on
                    fi
                  '';
                };
              in "${networkToggleScript}/bin/toggle-network";
            };

            bluetooth = {
              format-connected = "󰂱";
              format-on = "󰂯";
              format-off = "󰂲";
              format-disabled = "󰂲";
              format-no-controller = "󰂲";
              format-connected-battery = "󰥉";

              tooltip-format-disabled = "BT Disabled";
              tooltip-format-off = "BT Off";
              tooltip-format-on = "BT On";
              tooltip-format-connected = "Connected: {num_connections}\n{device_enumerate}";
              tooltip-format-connected-battery = "Connected: {num_connections}\n{device_enumerate}";
              tooltip-format-enumerate-connected = "Device: {device_alias}";
              tooltip-format-enumerate-connected-battery = "Device: {device_alias} 󰁹 {device_battery_percentage}%";

              on-click = "${pkgs.blueman}/bin/blueman-manager";
              on-click-right = let
                bluetoothPackage =
                  if nixosConfig != null
                  then nixosConfig.hardware.bluetooth.package
                  else pkgs.bluez;

                bluetoothToggleScript = pkgs.writeShellApplication {
                  name = "toogle-bluetooth";
                  runtimeInputs = [
                    bluetoothPackage
                  ];
                  text = ''
                    if [[ $(bluetoothctl show | grep PowerState | awk '{print $2}') == 'on' ]]; then
                      bluetoothctl power off
                    else
                      bluetoothctl power on
                    fi
                  '';
                };
              in "${bluetoothToggleScript}/bin/toogle-bluetooth";
            };

            wireplumber = {
              format = "{icon}";
              format-muted = "<span color=#ed8796>󰸈</span>";
              format-source = "";
              format-source-muted = "";
              format-icons = [
                "󰕿"
                "󰖀"
                "󰕾"
              ];
              states = {
                medium = 50;
                high = 80;
                very-high = 90;
              };

              tooltip-format = "{node_name}\n{icon}: {volume}%\n{format_source}: {source_volume}%";

              on-click = "${pkgs.pwvucontrol}/bin/pwvucontrol";
              on-click-right = let
                wireplumberToggleScript = pkgs.writeShellApplication {
                  name = "toggle-wireplumber";
                  runtimeInputs = [
                    pkgs.wireplumber
                  ];
                  text = ''
                    if [[ $(wpctl status | grep PowerState | awk '{print $2}') == 'on' ]]; then
                      wpctl set-volume @DEFAULT_SINK@ 0%
                    else
                      wpctl set-volume @DEFAULT_SINK@ 50%
                    fi
                  '';
                };
              in "${wireplumberToggleScript}/bin/toggle-wireplumber";
            };

            battery = {
              states = {
                low = 20;
                medium = 50;
                high = 80;
              };

              format-discharging-low = "󰁻";
              format-discharging-medium = "󰁾";
              format-discharging-high = "󰂁";
              format-charging-low = "󰂆";
              format-charging-medium = "󰢝";
              format-charging-high = "󰂊";
              format-full = "󰂅";

              tooltip-format = "Capacity: {percent}%\nDraw: {power}\nRemaining: {timeTo}\nHealth: {health}%";
            };

            backlight = {
              format = "{icon}";
              tooltip-format = "backlight: {percent}%";
              format-icons = [
                "󱩎"
                "󱩏"
                "󱩐"
                "󱩑"
                "󱩒"
                "󱩓"
                "󱩔"
                "󱩕"
                "󱩖"
              ];
            };

            "custom/separator" = {
              format = " | ";
            };

            "custom/spacer" = {
              format = " ";
            };
          };
        };

        style = ''
          * {
            background: transparent;
            border: none;
            border-radius: 0;
            font-family: "AurulentSansM Nerd Font Mono";
            font-size: 16px;
            min-height: 0;
          }

          .modules-left {
            background: rgb(36, 39, 58);
            border-radius: 1rem;
            margin: 8px 8px 0 8px;
          }

          .modules-center {
            background: rgb(36, 39, 58);
            border-radius: 1rem;
            margin: 8px 8px 0 8px;
          }

          .modules-right {
            background: rgb(36, 39, 58);
            border-radius: 1rem;
            margin: 8px 8px 0 8px;
          }

          tooltip {
            background: rgb(36, 39, 58);
            color: rgb(202, 211, 245);
            border: 1px solid rgb(54, 58, 79);
            border-radius: 1rem;
          }

          #workspaces button {
            padding-left: 12px;
            padding-right: 12px;
            font-weight: bold;
            background-color: transparent;
            color: rgb(91, 96, 120);
            border-radius: 50%;
          }

          #workspaces button:hover {
            background: rgb(110, 115, 141);
          }

          #workspaces button.active {
            color: rgb(138, 173, 244);
          }

          #workspaces button.urgent {
            color: rgb(237, 135, 150);
          }

          #cpu {
            color: rgb(166, 218, 149);
          }

          #cpu.medium {
            color: rgb(238, 212, 159);
          }

          #cpu.high {
            color: rgb(245, 169, 127);
          }

          #cpu.danger {
            color: rgb(237, 135, 150);
          }

          #memory {
            color: rgb(166, 218, 149);
          }

          #memory.medium {
            color: rgb(238, 212, 159);
          }

          #memory.high {
            color: rgb(245, 169, 127);
          }

          #memory.danger {
            color: rgb(237, 135, 150);
          }

          #network {
            font-size: 26px;
          }

          #bluetooth {
            font-size: 16px;
          }

          #bluetooth.disabled {
            color: rgb(54, 58, 79);
          }

          #bluetooth.off {
            color: rgb(54, 58, 79);
          }

          #bluetooth.no-controller {
            color: rgb(54, 58, 79);
          }

          #bluetooth.on {
            color: rgb(166, 218, 149);
          }

          #bluetooth.connected {
            color: rgb(125, 196, 228);
          }

          #wireplumber {
            color: rgb(166, 218, 149);
            font-size: 18px;
          }

          #wireplumber.medium {
            color: rgb(238, 212, 159);
          }

          #wireplumber.high {
            color: rgb(245, 169, 127);
          }

          #wireplumber.very-high {
            color: rgb(237, 135, 150);
          }

          #battery.discharging {
            font-size: 22px;
            color: rgb(166, 218, 149);
          }

          #battery.discharging.low {
            color: rgb(237, 135, 150);
          }

          #battery.discharging.medium {
            color: rgb(245, 169, 127);
          }

          #battery.discharging.high {
            color: rgb(238, 212, 159);
          }

          #battery.charging {
            color: rgb(166, 218, 149);
          }

          #battery.charging.low {
            color: rgb(237, 135, 150);
          }

          #battery.charging.medium {
            color: rgb(245, 169, 127);
          }

          #battery.charging.high {
            color: rgb(238, 212, 159);
          }

          #battery.full {
            color: rgb(166, 218, 149);
          }

          #backlight {
            font-size: 22px;
            color: rgb(238, 212, 159);
          }

          #cpu, #memory, #network, #bluetooth, #wireplumber, #backlight {
            margin: 0 4px;
          }

          #mpris {
            margin: 8px;
          }
        '';
      };

      wayland.windowManager.hyprland.settings.exec-once = [
        "uwsm app -s s -t service waybar"
      ];
    };
  }
