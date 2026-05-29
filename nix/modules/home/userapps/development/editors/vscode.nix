/**
VSCode editor module with GitHub Copilot agent integration.

This module treats VSCode as a dual-layer system:
  1. **Editor layer**:  VSCode settings, extensions, keybindings, XDG MIME types.
  2. **Agent layer**:   GitHub Copilot inside VSCode receives shared agent
                        context, subagents, skills, and MCP servers from the
                        `agentics.agents` namespace.

The agent features are wired through `programs.github-copilot-cli` (the
standalone CLI), which writes to `~/.config/copilot/`.  VSCode's Copilot
extension reads `copilot-instructions.md` from this directory (when pointed
to via settings) and MCP servers from `~/.config/Code/User/mcp.json`.
*/
{
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  cfg = config.userapps.development.editors.vscode;

  # Editor-level context (for the workspace / pair-programming guidance).
  editorCfg = config.userapps.development.agentics.editors;

  # Agent-level context (for the Copilot agent inside VSCode).
  agentsCfg = config.userapps.development.agentics.agents;

  mimeTypes = [
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

  # Auto-discover MCP server secrets from the **editor** MCP config.
  mcpSecrets = let
    extractSecretNames = attrs:
      lib.filter (v: v != null) (
        lib.mapAttrsToList (
          _: val:
            if builtins.isAttrs val && val ? "secret"
            then val.secret
            else null
        )
        attrs
      );
  in
    lib.flatten (lib.mapAttrsToList (
        _: srv:
          extractSecretNames (srv.env or {} // srv.headers or {})
      )
      editorCfg.mcp);

  allSecrets = lib.unique (cfg.secrets ++ mcpSecrets);

  # Vendor-specific package and MCP file path.
  vendorSpecs = {
    vscode = {
      package = pkgs.vscode;
      mcpPath = "${config.xdg.configHome}/Code/User/mcp.json";
    };
    oss-code = {
      package = pkgs.vscodium;
      mcpPath = "${config.xdg.configHome}/VSCodium/User/mcp.json";
    };
  };

  activeVendor = vendorSpecs.${cfg.vendor};

  # Translate an mcpServerSet value into the format VSCode's
  # github.copilot-chat extension expects for mcp.json.
  #
  # Format:
  #   { "mcpServers": { "<name>": { "type": "local", "command": …, … } } }
  translateMcpForVscode = name: mcpServer: let
    hasAnySecret = attrs:
      lib.any (v: builtins.isAttrs v && v ? "secret") (
        lib.attrValues attrs
      );

    hasEnvSecrets = hasAnySecret (mcpServer.env or {});
    hasHeaderSecrets = hasAnySecret (mcpServer.headers or {});

    renderEnvValue = value:
      if value ? "secret"
      then ''\${
          if value.prefix != null
          then value.prefix
          else ""
        }${value.environmentVariable}${
          if value.suffix != null
          then value.suffix
          else ""
        }''
      else ''${lib.escapeShellArg value}'';
  in
    if (mcpServer.transport == "stdio")
    then
      if hasEnvSecrets
      then let
        wrapperName = "vscode-mcp-stdio-${name}";
        envExports = lib.concatStringsSep "\n" (
          lib.mapAttrsToList (
            envName: value:
              if value ? "secret"
              then "export ${envName}=${renderEnvValue value}"
              else "export ${envName}=${lib.escapeShellArg value}"
          ) (mcpServer.env or {})
        );
        argsStr = lib.concatStringsSep " " (
          map lib.escapeShellArg (mcpServer.args or [])
        );
        wrapper = pkgs.writeShellScriptBin wrapperName ''
          ${envExports}
          exec ${lib.escapeShellArg mcpServer.command} ${argsStr}
        '';
      in {
        type = "local";
        command = "${wrapper}/bin/${wrapperName}";
      }
      else {
        type = "local";
        inherit (mcpServer) command;
        args = mcpServer.args or [];
        env = lib.mapAttrs (
          _: v:
            if builtins.isAttrs v
            then v.environmentVariable
            else v
        ) (mcpServer.env or {});
      }
    else if (mcpServer.transport == "http" || mcpServer.transport == "sse")
    then
      if hasHeaderSecrets
      then let
        wrapperName = "vscode-mcp-proxy-${name}";
        headerFlags = lib.concatStringsSep " \\\n                " (
          lib.mapAttrsToList (
            headerName: value:
              if value ? "secret"
              then "--headers '${headerName}' \"${renderEnvValue value}\""
              else "--headers '${headerName}' '${value}'"
          ) (mcpServer.headers or {})
        );
        transportFlag =
          if mcpServer.transport == "sse"
          then ""
          else "--transport streamablehttp";
        wrapper = pkgs.writeShellScriptBin wrapperName ''
          exec ${pkgs.mcp-proxy}/bin/mcp-proxy \
            ${transportFlag} \
            ${headerFlags} \
            '${mcpServer.url}'
        '';
      in {
        type = "local";
        command = "${wrapper}/bin/${wrapperName}";
      }
      else {
        type = "http";
        inherit (mcpServer) url;
        headers = mcpServer.headers or {};
      }
    else throw "Unsupported transport protocol: ${mcpServer.transport}";

  # Rendered MCP config for the VSCode mcp.json file.
  renderedVscodeMcpConfig = {
    mcpServers = lib.mapAttrs translateMcpForVscode editorCfg.mcp;
  };

  # Reuse the same MCP secret list computed above.
  vscodeMcpSecretNames = mcpSecrets;
in
  with lib; {
    options.userapps.development.editors.vscode = {
      enable = mkEnableOption ''
        Enable VSCode editor with GitHub Copilot agent integration.
        When `enableGithubCopilot` is on (default), the agent layer is
        wired automatically through the github-copilot agent harness.
      '';

      vendor = mkOption {
        type = types.enum [
          "vscode"
          "oss-code"
        ];
        default = "vscode";
        description = ''
          Which VSCode variant to use.

          - `vscode`    — upstream Microsoft Visual Studio Code
          - `oss-code`  — VSCodium (open-source build without MS telemetry)
        '';
      };

      enableGithubCopilot = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to integrate GitHub Copilot into VSCode.

          When enabled, the `github-copilot` agent harness is auto-activated,
          wiring shared agent context, subagents, skills, MCP servers, and
          the commands warning into the Copilot config directory
          (`~/.config/copilot/`).  VSCode's Copilot extension reads
          `copilot-instructions.md` from this directory and MCP servers from
          the per-vendor `mcp.json` file.
        '';
      };

      priority = mkOption {
        type = types.int;
        default = 20;
        description = "XDG MIME priority for VSCode as text editor.";
      };

      secrets = mkOption {
        type = with types; listOf str;
        default = [];
        description = ''
          List of sops secrets to inject into the VSCode runtime environment.
          The binary is wrapped with `makeWrapper` to export these as env vars.
        '';
      };

      extensions = mkOption {
        type = with types; listOf package;
        default = [];
        description = "List of VSCode extensions to install.";
      };

      settings = mkOption {
        type = with types; attrs;
        default = {};
        description = ''
          VSCode user settings written to `settings.json`.

          Merged on top of auto-generated settings (editor context, Copilot
          instructions path, etc.).
        '';
      };
    };

    config = mkIf cfg.enable (mkMerge [
      # ── Block 1: MIME associations, infrastructure deps ──────────────
      {
        xdg.mimeApps.defaultApplications = mkIf config.userapps.defaultApplications.enable (
          let
            editor = ["${baseNameOf (lib.getExe activeVendor.package)}.desktop"];
          in
            mkOverride cfg.priority (
              builtins.listToAttrs (map (mime: nameValuePair mime editor) mimeTypes)
            )
        );

        userapps.development.infrastructure.github = {
          enable = true;
          enableDesktop = true;
        };
      }

      # ── Block 2: Agent integration ──────────────────────────────────
      (mkIf cfg.enableGithubCopilot {
        # Auto-enable the github-copilot agent harness (writes context,
        # subagents, skills, MCP to ~/.config/copilot/).
        userapps.development.agents.github-copilot.enable = mkDefault true;

        warnings =
          optionals (agentsCfg.commands.registry != {})
          ''
            userapps.development.editors.vscode: commands are defined in
            `agentics.agents.commands.registry` but GitHub Copilot inside VSCode
            does not support custom slash commands.  These commands will not be
            available in the VSCode Copilot chat.  Move command-like instructions
            into `agentics.agents.subagents.registry` or provide them via
            `context` instead.
          ''
          ++ optionals (agentsCfg.subagents.registry != {})
          ''
            userapps.development.editors.vscode: subagents are defined in
            `agentics.agents.subagents.registry` but GitHub Copilot inside VSCode
            does not support custom agents (`.agent.md` files are read by the
            standalone CLI only).  These agents will not be available in the
            VSCode Copilot chat.
          ''
          ++ optionals (agentsCfg.skills != {})
          ''
            userapps.development.editors.vscode: skills are defined in
            `agentics.agents.skills` but GitHub Copilot inside VSCode does not
            support custom skills (they are read by the standalone CLI only).
            These skills will not be available in the VSCode Copilot chat.
          '';
      })

      # ── Block 3: VSCode program config ──────────────────────────────
      #
      # Only ONE mkIf block references cfg.extensions/cfg.settings to
      # avoid premature option evaluation during the module system's
      # pushDownProperties phase (see note at end of file).
      (mkIf (cfg.vendor == "vscode") {
        programs.vscode = {
          enable = true;
          inherit (cfg) extensions;

          userSettings =
            {
              # Inject the full editor-level context into the
              # Copilot chat instructions, plus a reference to the
              # global copilot-instructions.md written by the agent
              # harness so that the agent layer is also visible.
              "github.copilot.chat" = {
                instructions = [
                  {
                    sourceType = "text";
                    text = ''
                      # Editor Layer Context

                      ${editorCfg.context {}}
                    '';
                  }
                ];
              };
            }
            // cfg.settings;
        };
      })

      (mkIf (cfg.vendor == "oss-code") {
        programs.vscodium = {
          enable = true;
        };
      })

      # ── Block 4: MCP config ────────────────────────────────────────
      # Uses mkIf chains (not Nix if-then-else) to avoid forcing
      # vscodeMcpSecretNames during pushDownProperties.
      (mkIf (editorCfg.mcp != {} && vscodeMcpSecretNames == []) {
        xdg.configFile."Code/User/mcp.json" = {
          text = builtins.toJSON renderedVscodeMcpConfig;
        };
      })

      (mkIf (editorCfg.mcp != {} && vscodeMcpSecretNames != [] && options ? sops) {
        sops.secrets = genAttrs vscodeMcpSecretNames (_: {});

        sops.templates."vscode/mcp.json" = {
          content = builtins.toJSON renderedVscodeMcpConfig;
          path = "${config.xdg.configHome}/Code/User/mcp.json";
        };
      })

      (mkIf (editorCfg.mcp != {} && vscodeMcpSecretNames != [] && !(options ? sops)) {
        assertions = [
          {
            assertion = false;
            message = ''
              VS Code MCP config needs sops to render secret-backed values
              from `userapps.development.agentics.editors.mcp`.  Enable sops
              or remove secret-backed MCP server entries.
            '';
          }
        ];
      })

      # ── Block 5: Binary secret wrapping ─────────────────────────────
      (mkIf (options ? sops && allSecrets != []) {
        sops.secrets = genAttrs allSecrets (_: {});

        programs.vscode.package = let
          pkg = activeVendor.package;
        in
          mkForce (
            pkgs.symlinkJoin {
              inherit (pkg) pname;
              name = "${pkg.name}-wrapped";
              inherit (pkg) version;

              paths = [pkg];
              buildInputs = [pkgs.makeWrapper];
              postBuild = ''
                for bin in $out/bin/*; do
                  if [ -f "$bin" ] && [ -x "$bin" ]; then
                    wrapProgram "$bin" \
                      ${concatStringsSep " \\\n                  " (
                  map (
                    secret: "--run '[ -f ${config.sops.secrets.${secret}.path} ] && export ${baseNameOf secret}=\"$(cat ${
                      config.sops.secrets.${secret}.path
                    })\"'"
                  )
                  allSecrets
                )}
                  fi
                done
              '';
            }
          );
      })
    ]);
  }
