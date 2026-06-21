{
  lib,
  config,
  options,
  ...
}: let
  cfg = config.desktop.environments.display_managers.greetd.regreet;
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
          background = "#2e3440";
          login_box = "Aurora";
        };
      };

      extraCss = mkOption {
        type = with types; lines;
        default = "";
        description = ''
          Extra CSS rules to apply on top of the GTK theme for ReGreet.
        '';
        example = ''
          .login-box { background: rgba(46, 52, 64, 0.8); }
        '';
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        desktop.environments.display_managers.greetd.variant = "regreet";

        programs.regreet = {
          enable = true;
          inherit (cfg) settings extraCss;
        };
      }

      (mkIf (options ? stylix && config.stylix.enable) {
        programs.regreet.settings.theme = mkDefault "Adwaita";
      })
    ]);
  }
