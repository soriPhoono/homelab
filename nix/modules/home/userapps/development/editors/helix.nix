{
  lib,
  config,
  options,
  ...
}: let
  cfg = config.userapps.development.editors.helix;
in
  with lib; {
    options.userapps.development.editors.helix = {
      enable = mkEnableOption "Enable helix text editor";

      package = mkOption {
        type = with types; nullOr package;
        default = null;
        description = "The helix package to use. If null, uses pkgs.helix.";
        example = literalExpression "pkgs.evil-helix";
      };

      extraPackages = mkOption {
        type = with types; listOf package;
        default = [];
        description = "Extra packages available to hx (LSP servers, formatters, etc.).";
      };

      defaultEditor = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to configure hx as the default editor via EDITOR/VISUAL.";
      };

      settings = mkOption {
        type = types.attrs;
        default = {};
        description = "Helix editor settings written to config.toml.";
      };

      languages = mkOption {
        type = types.attrs;
        default = {};
        description = "Helix language configuration written to languages.toml.";
      };

      themes = mkOption {
        type = types.attrsOf (
          types.oneOf [
            types.attrs
            types.path
            types.str
          ]
        );
        default = {};
        description = "Helix themes to install.";
      };

      ignores = mkOption {
        type = with types; listOf str;
        default = [];
        description = "Glob patterns for file picker ignore rules.";
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        programs.helix = {
          enable = true;

          package = mkIf (cfg.package != null) cfg.package;

          inherit
            (cfg)
            extraPackages
            defaultEditor
            settings
            languages
            themes
            ignores
            ;
        };
      }

      (mkIf (options ? stylix && config.stylix.enable) {
        programs.helix.settings.theme = mkDefault "stylix";

        programs.helix.themes.stylix = let
          c = config.lib.stylix.colors;
        in {
          palette = {
            background = "#${c.base00}";
            foreground = "#${c.base05}";
            cursor = "#${c.base05}";
            base00 = "#${c.base00}";
            base01 = "#${c.base01}";
            base02 = "#${c.base02}";
            base03 = "#${c.base03}";
            base04 = "#${c.base04}";
            base05 = "#${c.base05}";
            base06 = "#${c.base06}";
            base07 = "#${c.base07}";
            base08 = "#${c.base08}";
            base09 = "#${c.base09}";
            base0A = "#${c.base0A}";
            base0B = "#${c.base0B}";
            base0C = "#${c.base0C}";
            base0D = "#${c.base0D}";
            base0E = "#${c.base0E}";
            base0F = "#${c.base0F}";
          };
        };
      })
    ]);
  }
