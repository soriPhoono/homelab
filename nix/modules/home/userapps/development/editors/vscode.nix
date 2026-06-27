{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.development.editors.vscode;

  # Translate agent MCP servers into VS Code userMcp format
  mcpUserMcp = {
    servers =
      builtins.mapAttrs (
        _name: srv:
          {
            inherit (srv) url;
            headers = srv.headers or {};
          }
          // (lib.optionalAttrs (srv.command != null) {
            inherit (srv) command;
            args = srv.args or [];
            env = srv.env or {};
          })
      )
      cfg.agent.mcpServers;
  };

  # Build VS Code editor profiles from extensionProfiles + common, filtered by activeProfiles.
  vscodeProfiles = let
    filtered = lib.filterAttrs (name: _: builtins.elem name cfg.activeProfiles) cfg.extensionProfiles;
  in
    lib.mapAttrs (_: profile: {
      extensions = cfg.common.extensions ++ profile.extensions;
      userSettings = cfg.userSettings // profile.userSettings;
      userTasks = cfg.common.userTasks // profile.userTasks;
      keybindings = cfg.common.keybindings ++ profile.keybindings;
      languageSnippets = cfg.common.languageSnippets // profile.languageSnippets;
      globalSnippets = cfg.common.globalSnippets // profile.globalSnippets;

      # Agent MCP servers wired into each profile
      userMcp = mcpUserMcp;
    })
    filtered;
in
  with lib; {
    options.userapps.development.editors.vscode = homelab.agentics.mkVscodeEditor {
      name = "vscode";
      package = pkgs.vscode;
    };

    config = mkIf cfg.enable {
      # Default editor — programs.vscode has no defaultEditor option
      home.sessionVariables = mkIf cfg.defaultEditor {
        EDITOR = "${lib.getExe cfg.package}";
        VISUAL = "${lib.getExe cfg.package}";
      };

      # Extra packages (LSP servers, formatters, linters)
      home.packages = cfg.extraPackages;

      # Delegate editor config to upstream programs.vscode module
      programs.vscode = {
        enable = true;
        inherit (cfg) package;
        profiles = vscodeProfiles;
      };

      # Wire agent context documents into Copilot's instructions directory.
      # These are consumed by the agent built into VS Code (e.g. GitHub Copilot).
      home.file =
        # Agent context documents
        lib.mapAttrs' (
          name: value:
            lib.nameValuePair ".copilot/instructions/${name}" (
              if builtins.isPath value
              then {source = value;}
              else {text = value;}
            )
        )
        cfg.agent.documents
        # Agent skills — each is a package symlinked into Copilot's skills dir
        // lib.mapAttrs' (
          name: pkg:
            lib.nameValuePair ".copilot/skills/${name}" {
              source = pkg;
              recursive = true;
            }
        )
        cfg.agent.skills;
    };
  }
