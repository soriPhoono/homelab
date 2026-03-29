{
  lib,
  config,
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
            height = 30;
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
              format = "{icon}";
              format-icons = [
                "<span color='#a6da95'>▁ </span>" # green
                "<span color='#a6da95'>▂ </span>" # blue
                "<span color='#a6da95'>▃ </span>" # white
                "<span color='#eed49f'>▄ </span>" # white
                "<span color='#eed49f'>▅ </span>" # yellow
                "<span color='#eed49f'>▆ </span>" # yellow
                "<span color='#f5a97f'>▇ </span>" # orange
                "<span color='#ed8796'>█ </span>" # red
              ];
            };

            memory = {
              format = "{percentage}% ";
              states = {
                low = 10;
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
            };

            bluetooth = {
              format-connected = "<span color='#a6da95'>󰣰</span>";
              format-on = "<span color='#a6da95'>󰣰</span>";
              format-off = "<span color='#363a4f'>󰣰</span>";
              format-disabled = "<span color='#363a4f'>󰣰</span>";
              format-no-controller = "<span color='#363a4f'>󰣰</span>";

              format-connected-battery = "<span color='#a6da95'>󰣰</span>";

              tooltip-format-disabled = "Bluetooth: 󰣰";
              tooltip-format-off = "Bluetooth: 󰣰";
              tooltip-format-on = "Bluetooth: 󰣰";
              tooltip-format-connected = "Bluetooth: 󰣰";
              tooltip-format-connected-battery = "Bluetooth: 󰣰";
              tooltip-format-enumerate-connected = "Bluetooth: 󰣰";
              tooltip-format-enumerate-connected-battery = "Bluetooth: 󰣰";
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
            font-size: 14px;
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
            border: 1px solid rgb(54, 58, 79);
            border-radius: 1rem;
          }

          #workspaces button {
            padding: 4px 8px;
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

          #memory.low {
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

          #cpu, #memory, #network {
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
