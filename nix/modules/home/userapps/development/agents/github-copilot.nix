{
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  agentsCfg = config.userapps.development.agents.agentics;
  cfg = config.userapps.development.agents.github-copilot;

  cmdFromEntry = _name: value:
    if builtins.isPath value
    then builtins.readFile value
    else value;

  # Auto-discover MCP server secrets from the agentics/agent MCP config.
  # Merges harness secrets (e.g. GITHUB_API_KEY for Copilot auth) with
  # MCP server secrets so both flow into the binary wrapper.
  mcpSecrets = lib.homelab.agentics.mcp.extractSecrets {
    stdio = agentsCfg.mcpServers.stdio or {};
    http = agentsCfg.mcpServers.http or {};
  };

  allSecrets = lib.unique (cfg.secrets ++ mcpSecrets);

  # Translate an mcpServerSet value into Copilot CLI's native MCP format.
  # For servers with secrets in env/headers, wrapper scripts are generated
  # that expand environment variables at runtime (the wrapped copilot binary
  # exports them via makeWrapper).  The wrapper is then registered as a local
  # MCP server, identical to the opencode mcp-proxy approach.
  translateMcpServer = name: mcpServer: let
    mcpLib = lib.homelab.agentics.mcp;
    inherit
      (mcpLib)
      renderEnvValue
      renderHeaderValue
      hasEnvSecrets
      hasHeaderSecrets
      ;
    isHttp = mcpServer ? "url" && mcpServer ? "headers";

    mkStdioNoSecrets = {
      type = "local";
      inherit (mcpServer) command;
      args = mcpServer.args or [];
      env = lib.mapAttrs (_: v:
        if builtins.isAttrs v
        then v.name
        else v) (mcpServer.env or {});
      tools = ["*"];
    };

    mkStdioSecrets = let
      envExports = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (envName: value: "export ${envName}=\"${renderEnvValue value}\"") (
          mcpServer.env or {}
        )
      );
      argsStr = lib.concatStringsSep " " (map lib.escapeShellArg (mcpServer.args or []));
      wrapper = pkgs.writeShellScriptBin "copilot-mcp-stdio-${name}" ''
        ${envExports}
        exec ${lib.escapeShellArg mcpServer.command} ${argsStr}
      '';
    in {
      type = "local";
      command = "${wrapper}/bin/copilot-mcp-stdio-${name}";
      args = [];
      tools = ["*"];
    };

    mkHttpNoSecrets = {
      type = "http";
      inherit (mcpServer) url;
      headers = mcpServer.headers or {};
      tools = ["*"];
    };

    mkHttpSecrets = let
      headerFlags = lib.concatStringsSep " \\\n                " (
        lib.mapAttrsToList (headerName: value: "--headers '${headerName}' \"${renderHeaderValue value}\"") (
          mcpServer.headers or {}
        )
      );
      wrapper = pkgs.writeShellScriptBin "copilot-mcp-proxy-${name}" ''
        exec ${pkgs.mcp-proxy}/bin/mcp-proxy \
          --transport streamablehttp \
          ${headerFlags} \
          '${mcpServer.url}'
      '';
    in {
      type = "local";
      command = "${wrapper}/bin/copilot-mcp-proxy-${name}";
      args = [];
      tools = ["*"];
    };
  in
    if isHttp
    then
      if hasHeaderSecrets mcpServer
      then mkHttpSecrets
      else mkHttpNoSecrets
    else if hasEnvSecrets mcpServer
    then mkStdioSecrets
    else mkStdioNoSecrets;
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
          ++ optionals (agentsCfg.commands or {} != {}) ''
            userapps.development.agents.github-copilot: commands are defined in
            `agentics.agents.commands.registry` but GitHub Copilot CLI does not
            support custom slash commands.  These commands will not be available
            in Copilot CLI.  Move command-like instructions into
            `agentics.agents.subagents.registry` (custom agents) or provide
            them via `programs.github-copilot-cli.context` instead.
          '';

        userapps.development.enable = true;

        programs.github-copilot-cli = {
          enable = true;
          enableMcpIntegration = false;

          context = let
            baseContext = agentsCfg.context or "";
          in ''
            # GitHub Copilot CLI Runtime Context

            This file provides machine-level and user-level context for Copilot CLI.
            Project-level repository guidance stays in the repository root
            `AGENTS.md` and `.agents/AGENTS.md`.

            ${baseContext}
          '';

          agents = mapAttrs cmdFromEntry agentsCfg.subagents;

          mcpServers = mapAttrs translateMcpServer (
            agentsCfg.mcpServers.stdio or {} // agentsCfg.mcpServers.http or {}
          );

          # Skill derivations contain SKILL.md as their primary output.
          # Read the content so the github-copilot-cli HM module can write it
          # to ~/.copilot/skills/<name>/SKILL.md (its .text field expects a
          # string, not a package).
          skills = mapAttrs (_name: pkg: builtins.readFile "${pkg}/SKILL.md") agentsCfg.skills;

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
