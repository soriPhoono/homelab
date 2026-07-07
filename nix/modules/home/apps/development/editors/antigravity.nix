{
  lib,
  config,
  pkgs,
  options,
  ...
}: let
  cfg = config.apps.development.editors.antigravity;

  codeMimeTypes = [
    "inode/x-empty"
    "text/plain"
    "text/markdown"
    "text/x-markdown"
    "text/javascript"
    "text/css"
    "text/x-csrc"
    "text/x-chdr"
    "text/x-c++src"
    "text/x-c++hdr"
    "text/x-cmake"
    "text/x-diff"
    "text/x-go"
    "text/x-java"
    "text/x-kotlin"
    "text/x-lua"
    "text/x-makefile"
    "text/x-nix"
    "text/x-python"
    "text/x-ruby"
    "text/x-rust"
    "text/x-script.python"
    "text/x-shellscript"
    "text/x-sql"
    "text/x-toml"
    "text/x-typescript"
    "text/x-typescript-jsx"
    "text/x-yaml"
    "application/json"
    "application/ld+json"
    "application/javascript"
    "application/toml"
    "application/xml"
    "application/x-shellscript"
    "application/x-yaml"
  ];

  # Translate agent MCP servers into Antigravity userMcp format
  mcpUserMcp = {
    servers =
      builtins.mapAttrs (
        _name: srv:
          (lib.optionalAttrs (srv.url != null) {
            inherit (srv) url;
            headers = srv.headers or {};
          })
          // (lib.optionalAttrs (srv.command != null) {
            inherit (srv) command;
            args = srv.args or [];
            env = srv.env or {};
          })
      )
      cfg.agent.mcpServers;
  };

  # Build Antigravity editor profiles from extensionProfiles + common, filtered by activeProfiles.
  vscodeProfiles = let
    filtered = lib.filterAttrs (name: _: builtins.elem name cfg.activeProfiles) cfg.extensionProfiles;
  in
    (lib.mapAttrs (_: profile: {
        extensions = cfg.common.extensions ++ profile.extensions;
        userSettings = cfg.userSettings // profile.userSettings;
        userTasks = cfg.common.userTasks // profile.userTasks;
        keybindings = cfg.common.keybindings ++ profile.keybindings;
        languageSnippets = cfg.common.languageSnippets // profile.languageSnippets;
        globalSnippets = cfg.common.globalSnippets // profile.globalSnippets;

        userMcp = mcpUserMcp;
      })
      filtered)
    // {
      default = {
        extensions = cfg.common.extensions;
        inherit (cfg) userSettings;
        userTasks = cfg.common.userTasks;
        keybindings = cfg.common.keybindings;
        languageSnippets = cfg.common.languageSnippets;
        globalSnippets = cfg.common.globalSnippets;
        userMcp = mcpUserMcp;
      };
    };

  # Stylix VS Code theme extension — only evaluated when stylix is available
  stylixThemeExt =
    if options ? stylix && config.stylix.enable
    then let
      c = config.lib.stylix.colors;

      # Theme JSON mapping base16 colors to VS Code theme color keys.
      # Full reference: https://github.com/nix-community/stylix/blob/master/modules/vscode/templates/theme.nix
      themeJson = builtins.toJSON (
        with c; rec {
          name = "Stylix";
          type =
            if config.stylix.polarity == "light"
            then "light"
            else "dark";
          colors = {
            "editor.background" = "#${base00}";
            "editor.foreground" = "#${base05}";
            "editorCursor.foreground" = "#${base05}";
            "editor.selectionBackground" = "#${base02}";
            "editorLineNumber.foreground" = "#${base03}";
            "editor.lineHighlightBackground" = "#${base01}";
            "editorBracketMatch.background" = "#${base03}";
            "editorWidget.background" = "#${base01}";
            "editorWidget.border" = "#${base02}";
            "editorGroupHeader.tabsBackground" = "#${base01}";
            "tab.activeBackground" = "#${base00}";
            "tab.inactiveBackground" = "#${base01}";
            "tab.activeForeground" = "#${base05}";
            "tab.inactiveForeground" = "#${base04}";
            "tab.border" = "#${base02}";
            "activityBar.background" = "#${base01}";
            "activityBar.foreground" = "#${base05}";
            "activityBarBadge.background" = "#${base0D}";
            "sideBar.background" = "#${base01}";
            "sideBar.foreground" = "#${base05}";
            "sideBarTitle.foreground" = "#${base05}";
            "titleBar.activeBackground" = "#${base01}";
            "titleBar.activeForeground" = "#${base05}";
            "statusBar.background" = "#${base00}";
            "statusBar.foreground" = "#${base05}";
            "panel.background" = "#${base00}";
            "panel.border" = "#${base02}";
            "input.background" = "#${base00}";
            "input.foreground" = "#${base05}";
            "input.border" = "#${base02}";
            "dropdown.background" = "#${base00}";
            "dropdown.foreground" = "#${base05}";
            "dropdown.border" = "#${base02}";
            "button.background" = "#${base0D}";
            "button.foreground" = "#${base00}";
            "badge.background" = "#${base02}";
            "badge.foreground" = "#${base05}";
            "list.activeSelectionBackground" = "#${base02}";
            "list.inactiveSelectionBackground" = "#${base02}";
            "list.hoverBackground" = "#${base02}";
            "focusBorder" = "#${base0D}";
            "progressBar.background" = "#${base0D}";
            "scrollbarSlider.background" = "#${base02}88";
            "scrollbarSlider.hoverBackground" = "#${base03}88";
            "scrollbarSlider.activeBackground" = "#${base04}88";
            "terminal.background" = "#${base00}";
            "terminal.foreground" = "#${base05}";
            "terminal.ansiBlack" = "#${base02}";
            "terminal.ansiRed" = "#${base08}";
            "terminal.ansiGreen" = "#${base0B}";
            "terminal.ansiYellow" = "#${base0A}";
            "terminal.ansiBlue" = "#${base0D}";
            "terminal.ansiMagenta" = "#${base0E}";
            "terminal.ansiCyan" = "#${base0C}";
            "terminal.ansiWhite" = "#${base05}";
            "terminal.ansiBrightBlack" = "#${base03}";
            "terminal.ansiBrightRed" = "#${base08}";
            "terminal.ansiBrightGreen" = "#${base0B}";
            "terminal.ansiBrightYellow" = "#${base0A}";
            "terminal.ansiBrightBlue" = "#${base0D}";
            "terminal.ansiBrightMagenta" = "#${base0E}";
            "terminal.ansiBrightCyan" = "#${base0C}";
            "terminal.ansiBrightWhite" = "#${base07}";
            "gitDecoration.modifiedResourceForeground" = "#${base0A}";
            "gitDecoration.deletedResourceForeground" = "#${base08}";
            "gitDecoration.untrackedResourceForeground" = "#${base0B}";
            "diffEditor.insertedTextBackground" = "#${base0B}4c";
            "diffEditor.removedTextBackground" = "#${base08}4c";
            "editorHoverWidget.background" = "#${base01}";
            "editorHoverWidget.border" = "#${base02}";
            "editorIndentGuide.background" = "#${base02}";
            "editorIndentGuide.activeBackground" = "#${base03}";
          };
          tokenColors = [
            {
              scope = ["comment" "punctuation.definition.comment"];
              settings = {
                foreground = "#${base03}";
                fontStyle = "italic";
              };
            }
            {
              scope = ["constant" "entity.name.constant" "variable.language"];
              settings = {foreground = "#${base08}";};
            }
            {
              scope = ["entity" "entity.name"];
              settings = {foreground = "#${base0A}";};
            }
            {
              scope = "entity.name.tag";
              settings = {foreground = "#${base08}";};
            }
            {
              scope = "keyword";
              settings = {foreground = "#${base0E}";};
            }
            {
              scope = ["string" "punctuation.definition.string"];
              settings = {foreground = "#${base0B}";};
            }
            {
              scope = ["storage.type" "storage.modifier"];
              settings = {foreground = "#${base0E}";};
            }
            {
              scope = ["support" "support.type" "support.class"];
              settings = {foreground = "#${base0C}";};
            }
            {
              scope = "support.function";
              settings = {foreground = "#${base0D}";};
            }
            {
              scope = ["entity.name.type" "meta.type"];
              settings = {foreground = "#${base09}";};
            }
            {
              scope = "variable.parameter.function";
              settings = {foreground = "#${base05}";};
            }
          ];
        }
      );

      packageJson = builtins.toJSON {
        name = "stylix-antigravity";
        displayName = "Stylix";
        version = "0.0.0";
        publisher = "stylix";
        description = "Base16 color theme configured via Stylix.";
        categories = ["Themes"];
        engines = {vscode = "^1.43.0";};
        contributes = {
          themes = [
            {
              label = "Stylix";
              uiTheme = "vs-dark";
              path = "./themes/stylix.json";
            }
          ];
        };
      };

      # Generate the extension source files as a derivation
      extensionSrc =
        pkgs.runCommandLocal "stylix-antigravity-src" {
          inherit themeJson packageJson;
          passAsFile = ["themeJson" "packageJson"];
        } ''
          mkdir -p "$out/themes"
          cp "$themeJsonPath" "$out/themes/stylix.json"
          cp "$packageJsonPath" "$out/package.json"
        '';
    in
      pkgs.vscode-utils.buildVscodeExtension {
        pname = "stylix-antigravity";
        vscodeExtPublisher = "stylix";
        vscodeExtName = "antigravity";
        vscodeExtUniqueId = "stylix.antigravity";
        version = "0.0.0";

        src = extensionSrc;
        sourceRoot = ".";

        meta.license = lib.licenses.mit;
      }
    else null;
in
  with lib; {
    options.apps.development.editors.antigravity = homelab.agentics.mkVscodeEditor {
      name = "antigravity";
      package = pkgs.google-antigravity-ide;
    };

    config = mkIf cfg.enable (mkMerge [
      {
        home.sessionVariables = mkIf cfg.defaultEditor {
          EDITOR = "${getExe cfg.package}";
          VISUAL = "${getExe cfg.package}";
        };

        # MIME type associations
        xdg.mimeApps.defaultApplications = mkIf config.apps.defaultApplications.enable (
          let
            editor = ["${baseNameOf (getExe cfg.package)}.desktop"];
          in
            mkOverride cfg.priority (
              builtins.listToAttrs (map (mime: nameValuePair mime editor) codeMimeTypes)
            )
        );

        programs.antigravity = {
          enable = true;
          inherit (cfg) package;
          profiles = vscodeProfiles;
        };

        # Wire agent context documents and skills into Antigravity IDE's
        # config directory. The IDE scans ~/.gemini/antigravity/ for global
        # agent config, and ~/.gemini/antigravity/skills/<name>/SKILL.md for
        # global skills.
        home.file =
          # Agent context documents
          mapAttrs' (
            name: value:
              nameValuePair ".gemini/antigravity/instructions/${name}" (
                if builtins.isPath value
                then {source = value;}
                else {text = value;}
              )
          )
          cfg.agent.documents
          # Agent skills — each is a package containing SKILL.md,
          # symlinked into Antigravity's global skills directory.
          // mapAttrs' (
            name: pkg:
              nameValuePair ".gemini/antigravity/skills/${name}" {
                source = pkg;
                recursive = true;
              }
          )
          cfg.agent.skills;
      }

      # Stylix theme: inject the base16 theme extension into every active profile
      (mkIf (options ? stylix && config.stylix.enable && stylixThemeExt != null) {
        programs.antigravity.profiles =
          mapAttrs (
            _name: profile:
              profile
              // {
                extensions = profile.extensions ++ [stylixThemeExt];
                userSettings =
                  profile.userSettings
                  // {
                    "workbench.colorTheme" = mkDefault "Stylix";
                  };
              }
          )
          vscodeProfiles;
      })
    ]);
  }
