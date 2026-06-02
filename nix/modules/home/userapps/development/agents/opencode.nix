{
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  agentsCfg = config.userapps.development.agentics.agents;
  cfg = config.userapps.development.agents.opencode;

  cmdFromEntry = _name: value:
    if builtins.isPath value
    then builtins.readFile value
    else value;

  # Auto-discover MCP server secrets from the agentics/agent MCP config.
  # Merges harness secrets (e.g. OPENROUTER_API_KEY for the model provider)
  # with MCP server secrets (e.g. CONTEXT7_API_KEY for MCP tools), so that
  # manually-declared provider secrets in cfg.secrets and auto-injected MCP
  # secrets from agentics/agents/mcp.nix both flow into the binary wrapper.
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
    lib.flatten (
      lib.mapAttrsToList (_: srv: extractSecretNames (srv.env or {} // srv.headers or {})) agentsCfg.mcp
    );

  allSecrets = lib.unique (cfg.secrets ++ mcpSecrets);
in
  with lib; {
    options.userapps.development.agents.opencode = {
      enable = mkEnableOption ''
        Enable the OpenCode agent runtime and write shared system/user context
        to `~/.config/opencode/AGENTS.md`.
      '';
      enableDesktop = mkEnableOption "Enable OpenCode desktop application (requires opencode-desktop package)";

      secrets = mkOption {
        type = with types; listOf str;
        description = ''
          List of secrets to be injected into OpenCode runtime environment. Each secret
          will be defined in `config.sops.secrets` and will be made available as an
          environment variable with the same name as the secret key.
          e.g.: api/GITHUB_API_TOKEN will be available as {env:GITHUB_API_TOKEN} in OpenCode runtime.
        '';
        default = [];
      };

      plugins = mkOption {
        type = with types; listOf str;
        default = [];
        description = ''
          npm package names to register as OpenCode plugins. Each name is added
          to the `plugin` array in OpenCode's config, causing OpenCode to
          auto-install and load them from npm at startup.

          e.g.: [ "opencode-swarm-plugin" ]
        '';
        example = ["opencode-swarm-plugin"];
      };

      settings = mkOption {
        type = with types; attrs;
        default = {};
        description = ''
          Attrs to express extra settings passed to opencode that do not belong to any other specific category. Also allows for advanced configuration via direct setting of configuration options
        '';
        example = {
          model = "opencode/deepseek-v4-flash";
        };
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        warnings =
          optionals (!(options ? sops) && cfg.secrets != [])
          "Failed to install opencode as it was requested with secrets embedment, which requires sops, which is currently disabled";

        home.packages = with pkgs;
          mkIf (cfg.enableDesktop && allSecrets == []) [
            opencode-desktop
          ];

        home.file =
          lib.mapAttrs' (name: pkg: {
            name = ".config/opencode/skills/${name}";
            value = {
              source = pkg;
              recursive = true;
            };
          })
          agentsCfg.skills;

        programs.opencode = {
          enable = true;
          context = ''
            # OpenCode Runtime Context

            This file provides machine-level and user-level context for OpenCode.
            Project-level repository guidance stays in the repository root
            `AGENTS.md` and `.agents/AGENTS.md`.

            ${agentsCfg.context {}}
          '';
          commands = mapAttrs cmdFromEntry agentsCfg.commands.registry;
          agents = mapAttrs cmdFromEntry agentsCfg.subagents.registry;
          settings =
            {
              mcp =
                builtins.mapAttrs (
                  name: mcpServer:
                    if (mcpServer.transport == "stdio")
                    then {
                      enabled = true;
                      type = "local";
                      command =
                        [
                          "${mcpServer.command}"
                        ]
                        ++ (mcpServer.args or []);
                      env =
                        builtins.mapAttrs (
                          _: value:
                            if value ? "secret"
                            then "${
                              if value.prefix != null
                              then value.prefix
                              else ""
                            }\${env:${value.environmentVariable}}${
                              if value.suffix != null
                              then value.suffix
                              else ""
                            }"
                            else value
                        )
                        mcpServer.env;
                    }
                    else if (mcpServer.transport == "http" || mcpServer.transport == "sse")
                    then let
                      wrapperName = "mcp-proxy-${name}";
                      # Build --headers flags with runtime env var expansion via the shell wrapper.
                      headerFlags = lib.concatStringsSep " \\\n                " (
                        lib.mapAttrsToList (
                          headerName: value:
                            if value ? "secret"
                            then "--headers '${headerName}' \"${
                              if value.prefix != null
                              then value.prefix
                              else ""
                            }\${${value.environmentVariable}}${
                              if value.suffix != null
                              then value.suffix
                              else ""
                            }\""
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
                      enabled = true;
                      type = "local";
                      command = [
                        "${wrapper}/bin/${wrapperName}"
                      ];
                    }
                    else throw "Unsupported transport protocol: ${mcpServer.transport}"
                )
                agentsCfg.mcp;
            }
            // cfg.settings
            // lib.optionalAttrs (cfg.plugins != []) {
              plugin = cfg.plugins;
            };
        };
      }
      (mkIf (options ? sops && allSecrets != []) {
        sops.secrets = genAttrs allSecrets (_: {});

        home.packages = let
          package = pkgs.opencode-desktop;
        in
          with pkgs; [
            (symlinkJoin {
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
            })
          ];

        programs.opencode.package = let
          package = pkgs.opencode;
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
