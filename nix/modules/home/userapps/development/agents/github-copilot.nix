{
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  agentsCfg = config.userapps.development.agentics.agents;
  cfg = config.userapps.development.agents.github-copilot;

  cmdFromEntry = _name: value:
    if builtins.isPath value
    then builtins.readFile value
    else value;

  # Auto-discover MCP server secrets from the agentics/agent MCP config.
  # Merges harness secrets (e.g. GITHUB_API_KEY for Copilot auth) with
  # MCP server secrets so both flow into the binary wrapper.
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
      agentsCfg.mcp);

  allSecrets = lib.unique (cfg.secrets ++ mcpSecrets);

  # Translate an mcpServerSet value into Copilot CLI's native MCP format.
  # For servers with secrets in env/headers, wrapper scripts are generated
  # that expand environment variables at runtime (the wrapped copilot binary
  # exports them via makeWrapper).  The wrapper is then registered as a local
  # MCP server, identical to the opencode mcp-proxy approach.
  translateMcpServer = name: mcpServer: let
    hasAnySecret = attrs:
      lib.any (v: builtins.isAttrs v && v ? "secret") (
        lib.attrValues attrs
      );

    hasEnvSecrets = hasAnySecret (mcpServer.env or {});
    hasHeaderSecrets = hasAnySecret (mcpServer.headers or {});

    # Render env entries: literal strings pass through, secrets are
    # resolved at runtime inside wrapper scripts (for stdio) or via
    # mcp-proxy (for http/sse).
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
        wrapperName = "copilot-mcp-stdio-${name}";
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
        args = [];
        tools = ["*"];
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
        tools = ["*"];
      }
    else if (mcpServer.transport == "http" || mcpServer.transport == "sse")
    then
      if hasHeaderSecrets
      then let
        wrapperName = "copilot-mcp-proxy-${name}";
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
        args = [];
        tools = ["*"];
      }
      else {
        type =
          if mcpServer.transport == "sse"
          then "sse"
          else "http";
        inherit (mcpServer) url;
        headers = mcpServer.headers or {};
        tools = ["*"];
      }
    else throw "Unsupported transport protocol: ${mcpServer.transport}";
in
  with lib; {
    options.userapps.development.agents.github-copilot = {
      enable = mkEnableOption ''
        Enable the GitHub Copilot CLI agent runtime and write shared system/user
        context to the Copilot CLI configuration directory.
      '';

      secrets = mkOption {
        type = with types; listOf str;
        default = ["api/GITHUB_API_KEY"];
        description = ''
          List of secrets to be injected into the Copilot CLI runtime environment.
          Each secret will be defined in `config.sops.secrets` and will be made
          available as an environment variable with the same name as the secret's
          `baseNameOf`.

          Defaults to `["api/GITHUB_API_KEY"]` as GitHub Copilot requires a
          GitHub token for authentication.
        '';
      };

      settings = mkOption {
        type = with types; attrs;
        default = {};
        description = ''
          Extra settings to pass through to `programs.github-copilot-cli.settings`.
          Merged on top of any auto-configured values.

          See https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-config-dir-reference
          for available configuration keys.
        '';
        example = {
          model = "claude-sonnet-4-5";
          renderMarkdown = true;
          autoUpdate = false;
        };
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        warnings =
          optionals (!(options ? sops) && cfg.secrets != [])
          "Failed to install github-copilot-cli as it was requested with secrets embedment, which requires sops, which is currently disabled"
          ++ optionals (agentsCfg.commands.registry != {})
          ''
            userapps.development.agents.github-copilot: commands are defined in
            `agentics.agents.commands.registry` but GitHub Copilot CLI does not
            support custom slash commands.  These commands will not be available
            in Copilot CLI.  Move command-like instructions into
            `agentics.agents.subagents.registry` (custom agents) or provide
            them via `programs.github-copilot-cli.context` instead.
          '';

        programs.github-copilot-cli = {
          enable = true;
          enableMcpIntegration = false;

          context = let
            # Collect any context entries that don't fit Copilot CLI's native options
            baseContext = agentsCfg.context {};
          in ''
            # GitHub Copilot CLI Runtime Context

            This file provides machine-level and user-level context for Copilot CLI.
            Project-level repository guidance stays in the repository root
            `AGENTS.md` and `.agents/AGENTS.md`.

            ${baseContext}
          '';

          agents = mapAttrs cmdFromEntry agentsCfg.subagents.registry;

          mcpServers = mapAttrs translateMcpServer agentsCfg.mcp;

          # Skill derivations contain SKILL.md as their primary output.
          # Read the content so the github-copilot-cli HM module can write it
          # to ~/.copilot/skills/<name>/SKILL.md (its .text field expects a
          # string, not a package).
          skills =
            mapAttrs (
              _name: pkg:
                builtins.readFile "${pkg}/SKILL.md"
            )
            agentsCfg.skills;

          inherit (cfg) settings;
        };
      }
      (mkIf (options ? sops && allSecrets != []) {
        sops.secrets = genAttrs allSecrets (_: {});

        programs.github-copilot-cli.package = let
          package = pkgs.github-copilot-cli;
        in
          with pkgs;
            symlinkJoin {
              inherit (package) pname;
              name = "${package.name}-wrapped";
              inherit (package) version;

              paths = [package];
              buildInputs = [makeWrapper];
              postBuild = ''
                for bin in $out/bin/*; do
                  # Ensure it is actually a file and is executable before wrapping
                  if [ -f "$bin" ] && [ -x "$bin" ]; then
                    # Pass ALL --run commands into a SINGLE wrapProgram invocation
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
            };
      })
    ]);
  }
