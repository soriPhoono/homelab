{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.development.editors.antigravity-ide;

  # MIME types for Antigravity IDE file associations
  antigravityMimeTypes = [
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
    "text/x-yaml"
    "application/json"
    "application/xml"
    "application/x-yaml"
    "inode/directory"
  ];
in
  with lib; {
    options.userapps.development.editors.antigravity-ide = homelab.agentics.mkEditor {
      name = "antigravity-ide";
      package = pkgs.google-antigravity-ide;
      extraOptions = {
        # ── AI / Agent features ──────────────
        enableAgents = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Enable the Antigravity agent manager and agent-powered features:
            inline editing, task running, and context-aware completions.
          '';
        };

        enableAgentCompletions = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Enable agent-powered tab completions and inline code suggestions.
          '';
        };

        enableArtifacts = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Antigravity artifacts (generated files, previews, and visual outputs).";
        };

        enableTerminalAgent = mkOption {
          type = types.bool;
          default = true;
          description = "Enable the Antigravity terminal agent (`agy`).";
        };

        enableMCP = mkOption {
          type = types.bool;
          default = true;
          description = "Enable MCP (Model Context Protocol) server support.";
        };

        enableAutoUpdate = mkOption {
          type = types.bool;
          default = false;
          description = "Enable automatic updates (disabled — managed by Nix flake).";
        };

        enableTelemetry = mkOption {
          type = types.bool;
          default = false;
          description = "Enable telemetry and usage reporting (off by default).";
        };
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        # Default editor env vars
        home.sessionVariables = mkIf cfg.defaultEditor {
          EDITOR = "${lib.getExe cfg.package}";
          VISUAL = "${lib.getExe cfg.package}";
        };

        # MIME type associations
        xdg.mimeApps.defaultApplications = mkIf config.userapps.defaultApplications.enable (
          let
            editor = ["${baseNameOf (lib.getExe cfg.package)}.desktop"];
          in
            mkOverride cfg.priority (
              builtins.listToAttrs (map (mime: lib.nameValuePair mime editor) antigravityMimeTypes)
            )
        );

        # Packages: extra packages + agy CLI + the IDE itself
        home.packages =
          cfg.extraPackages
          ++ (optional cfg.enableTerminalAgent pkgs.google-antigravity-cli)
          ++ [cfg.package];

        # ── Antigravity settings.json ────────
        xdg.configFile."antigravity/settings.json" = let
          defaults = {
            "antigravity.agent.enabled" = cfg.enableAgents;
            "antigravity.agent.completions.enabled" = cfg.enableAgentCompletions;
            "antigravity.artifacts.enabled" = cfg.enableArtifacts;
            "antigravity.terminalAgent.enabled" = cfg.enableTerminalAgent;
            "antigravity.mcp.enabled" = cfg.enableMCP;
            "antigravity.update.autoCheck" = cfg.enableAutoUpdate;
            "antigravity.update.channel" = "stable";
            "antigravity.telemetry.enabled" = cfg.enableTelemetry;
          };
        in {
          text = builtins.toJSON (defaults // cfg.userSettings);
        };
      }
    ]);
  }
