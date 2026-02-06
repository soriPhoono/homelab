{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.desktop.environments.hyprland.default;
  core = config.desktop.environments.hyprland;
in {
  imports = [
    ./conf/hypr.nix
    ./conf/binds.nix
    ./shell.nix
  ];

  options.desktop.environments.hyprland.default = {
    enable = mkEnableOption "Enable default hyprland desktop";

    caelestia = {
      enable = mkEnableOption "Enable caelestia shell components" // {default = true;};
      settings = mkOption {
        type = with types;
          submodule {
            freeformType = attrs;
            options = {};
          };
        default = {};
        description = "Settings to pass to the caelestia shell";
      };
    };

    appearance = {
      rounding = mkOption {
        type = types.int;
        default = 10;
        description = "Window corner rounding radius";
      };
      borderSize = mkOption {
        type = types.int;
        default = 3;
        description = "Window border thickness";
      };
      activeOpacity = mkOption {
        type = types.float;
        default = 0.9;
        description = "Opacity of the active window";
      };
      inactiveOpacity = mkOption {
        type = types.float;
        default = 0.9;
        description = "Opacity of inactive windows";
      };
    };
  };

  config = mkIf (core.enable && !core.custom) {
    desktop.environments.hyprland = {
      default.enable = true;

      components = mkIf cfg.caelestia.enable [
        {
          name = "caelestia-shell";
          command = "caelestia-shell";
          type = "service";
          background = true;
          reloadBehavior = "restart";
        }
      ];

      binds = flatten (let
        directions = {
          left = "l";
          right = "r";
          up = "u";
          down = "d";
          H = "l";
          L = "r";
          K = "u";
          J = "d";
        };
      in
        [
          # Cycle windows
          {
            key = "Tab";
            dispatcher = "cyclenext";
          }
          {
            mods = ["$mod" "SHIFT"];
            key = "Tab";
            dispatcher = "cyclenext";
            params = "prev";
          }
        ]
        # Window management
        ++ (mapAttrsToList (key: dispatcher: {
            inherit key dispatcher;
          }) {
            Q = "killactive";
            F = "fullscreen";
            V = "togglefloating";
            P = "pseudo";
            S = "togglesplit";
          })
        # Screenshotting
        ++ (map (item: {
            mods = item.mods or ["$mod"];
            key = "Print";
            dispatcher = "exec";
            params = "${pkgs.uwsm}/bin/uwsm app -- ${config.programs.hyprshot.package}/bin/hyprshot -m ${item.params}";
          }) [
            {params = "active -m output";}
            {
              mods = ["$mod" "SHIFT"];
              params = "active -m window";
            }
            {
              mods = ["$mod" "ALT"];
              params = "region";
            }
          ])
        ++ (builtins.genList (i: [
            {
              key = toString (i + 1);
              dispatcher = "workspace";
              params = toString (i + 1);
            }
            {
              mods = ["$mod" "SHIFT"];
              key = toString (i + 1);
              dispatcher = "movetoworkspace";
              params = toString (i + 1);
            }
          ])
          9)
        # Movement and Resizing
        ++ (mapAttrsToList (key: dir: [
            {
              inherit key;
              dispatcher = "movefocus";
              params = dir;
              type = "binde";
            }
            {
              mods = ["$mod" "SHIFT"];
              inherit key;
              dispatcher = "movewindow";
              params = dir;
              type = "binde";
            }
            {
              mods = ["$mod" "CTRL"];
              inherit key;
              dispatcher = "resizeactive";
              params =
                if dir == "l"
                then "-40 0"
                else if dir == "r"
                then "40 0"
                else if dir == "u"
                then "0 -40"
                else "0 40";
              type = "binde";
            }
          ])
          directions)
        ++ [
          # Mouse bindings
          {
            type = "bindm";
            mods = ["ALT"];
            key = "mouse:272";
            dispatcher = "movewindow";
          }
        ]);
    };
  };
}
