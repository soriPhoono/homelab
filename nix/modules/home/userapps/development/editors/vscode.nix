{
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  cfg = config.userapps.development.editors.vscode;

  vendorSpecs = {
    "oss-code" = {
      package = pkgs.vscodium;
      enableGithubDesktop = false;
      enableGithubCopilot = false;
      mcp = null;
    };
    vscode = {
      package = pkgs.vscode;
      enableGithubDesktop = true;
      enableGithubCopilot = true;
      mcp = {
        rootKey = "servers";
        includeTransportType = true;
        remoteUrlField = "url";
        target = {
          kind = "xdgConfig";
          path = "Code/User/mcp.json";
        };
        templateName = "vscode/mcp.json";
        secretMessage = "VS Code MCP config needs sops to render secret-backed values from `userapps.development.agents.mcp`.";
      };
    };
    antigravity = {
      package = pkgs.antigravity;
      enableGithubDesktop = true;
      enableGithubCopilot = false;
      mcp = {
        rootKey = "mcpServers";
        includeTransportType = false;
        remoteUrlField = "serverUrl";
        target = {
          kind = "homeFile";
          path = ".gemini/antigravity/mcp_config.json";
        };
        templateName = "antigravity/mcp.json";
        secretMessage = "Antigravity MCP config needs sops to render secret-backed values from `userapps.development.agents.mcp`.";
      };
    };
  };
in
  with lib; {
    config = mkIf cfg.enable (mkMerge [
      (mkIf activeVendor.enableGithubCopilot {
        userapps.development.agents.github-copilot = {
          enable = mkDefault true;
        };
      })
      (mkIf (cfg.vendor == "oss-code") {
        programs.vscodium = editorProgramSettings;
      })
      (mkIf (cfg.vendor == "vscode") {
        programs.vscode = editorProgramSettings;
      })
      (mkIf (cfg.vendor == "antigravity") {
        userapps.development.agents.gemini.enable = true;
        programs.antigravity = editorProgramSettings;
      })
      (mkIf (cfg.vendor == "vscode" && mcpCfg.consumers.editors.vscode.enable) (mkMerge [
        (mkIf (vscodeMcpSecretNames == []) {
          xdg.configFile."Code/User/mcp.json".text = builtins.toJSON renderedVscodeMcpConfig;
        })
        (mkIf (options ? sops && vscodeMcpSecretNames != []) {
          sops.secrets = genAttrs vscodeMcpSecretNames (_: {});

          sops.templates."${vendorSpecs.vscode.mcp.templateName}" = {
            content = builtins.toJSON renderedVscodeMcpConfig;
            path = "${config.xdg.configHome}/${vendorSpecs.vscode.mcp.target.path}";
          };
        })
        (mkIf (!(options ? sops) && vscodeMcpSecretNames != []) {
          assertions = [
            {
              assertion = false;
              message = vendorSpecs.vscode.mcp.secretMessage;
            }
          ];
        })
      ]))
      (mkIf (cfg.vendor == "antigravity" && mcpCfg.consumers.editors.vscode.enable) (mkMerge [
        (mkIf (vscodeMcpSecretNames == []) {
          home.file."${vendorSpecs.antigravity.mcp.target.path}".text =
            builtins.toJSON renderedAntigravityMcpConfig;
        })
        (mkIf (options ? sops && vscodeMcpSecretNames != []) {
          sops.secrets = genAttrs vscodeMcpSecretNames (_: {});

          sops.templates."${vendorSpecs.antigravity.mcp.templateName}" = {
            content = builtins.toJSON renderedAntigravityMcpConfig;
            path = "${config.home.homeDirectory}/${vendorSpecs.antigravity.mcp.target.path}";
          };
        })
        (mkIf (!(options ? sops) && vscodeMcpSecretNames != []) {
          assertions = [
            {
              assertion = false;
              message = vendorSpecs.antigravity.mcp.secretMessage;
            }
          ];
        })
      ]))
      (mkIf (cfg.vendor == "cursor" && mcpCfg.consumers.editors.vscode.enable) (mkMerge [
        (mkIf (vscodeMcpSecretNames == []) {
          home.file."${vendorSpecs.cursor.mcp.target.path}".text = builtins.toJSON renderedCursorMcpConfig;
        })
        (mkIf (options ? sops && vscodeMcpSecretNames != []) {
          sops.secrets = genAttrs vscodeMcpSecretNames (_: {});

          sops.templates."${vendorSpecs.cursor.mcp.templateName}" = {
            content = builtins.toJSON renderedCursorMcpConfig;
            path = "${config.home.homeDirectory}/${vendorSpecs.cursor.mcp.target.path}";
          };
        })
        (mkIf (!(options ? sops) && vscodeMcpSecretNames != []) {
          assertions = [
            {
              assertion = false;
              message = vendorSpecs.cursor.mcp.secretMessage;
            }
          ];
        })
      ]))
    ]);
  }
