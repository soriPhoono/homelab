{
  lib,
  config,
  options,
  ...
}: let
  inherit (lib) optionalString;

  cfg = config.desktop.environments.display_managers.greetd.regreet;
  stylixEnabled = options ? stylix && config.stylix.enable;
  colors = config.lib.stylix.colors or {};
  c = colors.withHashtag or {};

  baseCss =
    ''
      frame.background {
        background-color: ${c.base01 or "#282828"};
        border: 1px solid ${c.base02 or "#383838"};
        border-radius: 12px;
      }

      entry {
        background-color: ${c.base02 or "#383838"};
        color: ${c.base05 or "#d8d8d8"};
        border: 1px solid ${c.base03 or "#585858"};
        border-radius: 8px;
        caret-color: ${c.base0D or "#7cafc2"};
      }

      entry:focus {
        border-color: ${c.base0D or "#7cafc2"};
      }

      passwordentry {
        background-color: ${c.base02 or "#383838"};
        color: ${c.base05 or "#d8d8d8"};
        border: 1px solid ${c.base03 or "#585858"};
        border-radius: 8px;
        caret-color: ${c.base0D or "#7cafc2"};
      }

      passwordentry:focus {
        border-color: ${c.base0D or "#7cafc2"};
      }

      label {
        color: ${c.base05 or "#d8d8d8"};
      }

      label:disabled {
        color: ${c.base03 or "#585858"};
      }

      button {
        background-color: ${c.base0D or "#7cafc2"};
        color: ${c.base00 or "#181818"};
        border: none;
        border-radius: 8px;
        font-weight: bold;
      }

      button:hover {
        background-color: ${c.base0C or "#86c1b9"};
      }

      button.suggested-action {
        background-color: ${c.base0D or "#7cafc2"};
        color: ${c.base00 or "#181818"};
      }

      button.suggested-action:hover {
        background-color: ${c.base0C or "#86c1b9"};
      }

      button.destructive-action {
        background-color: transparent;
        color: ${c.base08 or "#ab4642"};
      }

      button.destructive-action:hover {
        background-color: ${c.base08 or "#ab4642"};
        color: ${c.base00 or "#181818"};
      }

      combobox button {
        background-color: ${c.base02 or "#383838"};
        color: ${c.base05 or "#d8d8d8"};
      }

      togglebutton {
        background-color: ${c.base02 or "#383838"};
        color: ${c.base05 or "#d8d8d8"};
      }
    ''
    + optionalString (cfg.background.enable && cfg.background.path != null) ''
      window {
        background-image: url("${cfg.background.path}");
        background-repeat: no-repeat;
        background-position: center;
        background-size: cover;
      }
    ''
    + optionalString (!cfg.background.enable || cfg.background.path == null) ''
      picture {
        background-color: ${c.base00 or "#181818"};
      }
    '';
in
  with lib; {
    options.desktop.environments.display_managers.greetd.regreet = {
      enable = mkEnableOption "Enable regreet as the greetd greeter";

      settings = mkOption {
        type = with types; attrsOf anything;
        default = {};
        description = ''
          ReGreet configuration options. Refer to
          https://github.com/rharish101/ReGreet/blob/main/regreet.sample.toml
          for available options.
        '';
        example = {
          appearance.greeting_msg = "Welcome back!";
          background = {
            path = "/usr/share/backgrounds/greeter.jpg";
            fit = "Cover";
          };
        };
      };

      extraCss = mkOption {
        type = with types; lines;
        default = "";
        description = ''
          Extra CSS rules appended after the auto-generated stylix theme.
        '';
        example = ''
          window.background {
            background-color: #2e3440;
          }
        '';
      };

      background = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to show a background image.";
        };

        path = mkOption {
          type = with types; nullOr str;
          default = null;
          description = "Path to the background image. Defaults to stylix wallpaper when stylix is enabled.";
        };

        fit = mkOption {
          type = with types; nullOr (enum ["Fill" "Contain" "Cover" "ScaleDown"]);
          default = "Cover";
          description = "How the background image fits the screen.";
        };
      };

      stylix = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to apply stylix theming to ReGreet.";
        };
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        desktop.environments.display_managers.greetd.variant = "regreet";

        programs.regreet = {
          enable = true;
          inherit (cfg) settings;
        };
      }

      (mkIf (stylixEnabled && cfg.stylix.enable) {
        desktop.environments.display_managers.greetd.regreet.background.path = mkDefault config.stylix.image;

        programs.regreet = {
          theme.name = mkDefault "Adwaita";

          font = {
            name = mkDefault (config.stylix.fonts.sansSerif.name or "Cantarell");
            size = mkDefault 12;
          };

          cursorTheme.name = mkDefault (
            config.stylix.cursor.name or "Adwaita"
          );

          iconTheme.name = mkDefault "Adwaita";

          extraCss =
            baseCss + cfg.extraCss;

          settings = {
            GTK = {
              application_prefer_dark_theme = mkDefault (
                config.stylix.polarity == "dark"
              );
              theme_name = mkDefault "Adwaita";
            };
          };
        };
      })
    ]);
  }
