{
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  cfg = config.userapps.development.agents.opencode;
  shared = config.userapps.development.agents.agentics or {};

  # Merge shared agentics config with per-agent overrides (per-agent wins)
  mcpServers = {
    stdio = (shared.mcpServers.stdio or {}) // cfg.mcpServers.stdio;
    http = (shared.mcpServers.http or {}) // cfg.mcpServers.http;
  };
  skills = (shared.skills or {}) // cfg.skills;
  subagents =
    if builtins.isAttrs cfg.subagents && cfg.subagents != {}
    then cfg.subagents
    else shared.subagents or {};
  commands = (shared.commands or {}) // cfg.commands;
  agentContext =
    if cfg.context != ""
    then cfg.context
    else shared.context or "";

  # ---- Env / header renderers (agentics → shell-friendly $VAR syntax) ----

  mcpLib = lib.homelab.agentics.mcp;
  inherit
    (mcpLib)
    renderEnvValue
    renderHeaderValue
    hasEnvSecrets
    hasHeaderSecrets
    ;

  # ---- MCP server translation ----

  translateMcpServer = name: srv:
    if (srv ? "url" && srv ? "headers")
    then
      # HTTP / SSE → OpenCode remote MCP server
      if hasHeaderSecrets srv
      then
        # Headers contain secrets → wrap via mcp-proxy with runtime env expansion
        let
          wrapperName = "opencode-mcp-proxy-${name}";
          headerFlags = lib.concatStringsSep " \\\n            " (
            lib.mapAttrsToList (
              hname: val:
                if val ? "secret"
                then "--headers '${hname}' \"${renderHeaderValue val}\""
                else "--headers '${hname}' '${val}'"
            ) (srv.headers or {})
          );
          transportFlag =
            if srv.transport or "http" == "sse"
            then ""
            else "--transport streamablehttp";
          wrapper = pkgs.writeShellScriptBin wrapperName ''
            exec ${pkgs.mcp-proxy}/bin/mcp-proxy \
              ${transportFlag} \
              ${headerFlags} \
              '${srv.url}'
          '';
        in {
          type = "local";
          command = ["${wrapper}/bin/${wrapperName}"];
          env = {};
          enabled = true;
        }
      else {
        type = "remote";
        inherit (srv) url;
        headers = lib.mapAttrs (_: renderHeaderValue) (srv.headers or {});
        enabled = true;
      }
    else
      # Stdio → OpenCode local MCP server
      let
        env = lib.mapAttrs (_: renderEnvValue) (srv.env or {});
      in
        if hasEnvSecrets srv
        then
          # Env contains secrets → wrap via shell script that exports at runtime
          let
            wrapperName = "opencode-mcp-stdio-${name}";
            envExports = lib.concatStringsSep "\n" (
              lib.mapAttrsToList (
                envName: val:
                  if val ? "secret"
                  then "export ${val.name}=\"${renderEnvValue val}\""
                  else "export ${envName}=${lib.escapeShellArg val}"
              ) (srv.env or {})
            );
            argsStr = lib.concatStringsSep " " (map lib.escapeShellArg (srv.args or []));
            wrapper = pkgs.writeShellScriptBin wrapperName ''
              ${envExports}
              exec ${lib.escapeShellArg srv.command} ${argsStr}
            '';
          in {
            type = "local";
            command = ["${wrapper}/bin/${wrapperName}"];
            env = {};
            enabled = true;
          }
        else {
          type = "local";
          command = [srv.command] ++ (srv.args or []);
          inherit env;
          enabled = true;
        };

  # ---- Gather secrets from MCP servers ----

  mcpSecrets = mcpLib.extractSecrets {
    inherit (mcpServers) stdio http;
  };

  allSecrets = lib.unique (cfg.secrets ++ mcpSecrets);

  # ---- Assemble the OpenCode JSON config ----

  opencodeJson =
    {
      mcp = builtins.mapAttrs translateMcpServer (mcpServers.stdio // mcpServers.http);
    }
    // lib.optionalAttrs (builtins.isAttrs subagents && subagents != {}) (
      let
        mkSubagentEntry = _name: value: value;
      in {
        agent = builtins.mapAttrs mkSubagentEntry subagents;
      }
    )
    // lib.optionalAttrs (commands != {}) {
      command = commands;
    }
    // lib.optionalAttrs (cfg.plugins or [] != []) {
      plugin = cfg.plugins;
    }
    // cfg.settings;

  # ---- Context wrapper ----

  createContext = ctx: ''
    # OpenCode Runtime Context

    This file provides machine-level and user-level context for OpenCode.
    Project-level repository guidance stays in the repository root
    `AGENTS.md` and `.agents/AGENTS.md`.

    ${ctx}
  '';
in
  with lib; {
    options.userapps.development.agents.opencode = homelab.agentics.mkAgent {
      name = "opencode";
      package = pkgs.opencode;
      extraOptions = {
        enableDesktop = mkEnableOption "Enable the OpenCode desktop application (opencode-desktop)";

        plugins = mkOption {
          type = with types; listOf str;
          default = [];
          description = ''
            npm package names to register as OpenCode plugins. Each name is added
            to the `plugin` array in opencode.json, causing OpenCode to
            auto-install and load them from npm at startup.

            e.g.: [ "opencode-swarm-plugin" ]
          '';
          example = ["opencode-swarm-plugin"];
        };

        settings = mkOption {
          type = with types; attrs;
          default = {};
          description = ''
            Extra settings to merge into the generated opencode.json.
            These act as global defaults for OpenCode — providers, models,
            permissions, autoupdate, etc.

            See https://opencode.ai/docs/config/ for the full schema.
          '';
          example = {
            model = "anthropic/claude-sonnet-4-5";
            autoupdate = true;
          };
        };
      };
    };

    config = mkIf cfg.enable (mkMerge [
      # Provide a default empty context so `cfg.context` is always safe to read.
      # Users override via `userapps.development.agents.opencode.context` or
      # `userapps.development.agents.agentics.context`.
      {userapps.development.agents.opencode.context = mkDefault "";}

      # ── Base config ──
      {
        home = {
          packages = mkMerge [
            (mkIf (allSecrets == []) [cfg.package])
            (mkIf (cfg.enableDesktop && allSecrets == []) [pkgs.opencode-desktop])
          ];

          file = mkMerge [
            {
              ".config/opencode/opencode.json".text = builtins.toJSON opencodeJson;
            }

            # Write context to ~/.config/opencode/AGENTS.md.
            (mkIf (agentContext != "") (
              if builtins.typeOf agentContext == "path"
              then {
                ".config/opencode/AGENTS.md".text = createContext (builtins.readFile agentContext);
              }
              else {
                ".config/opencode/AGENTS.md".text = createContext agentContext;
              }
            ))

            # Link skills.
            (mkIf (skills != {}) (
              mapAttrs' (name: skill: {
                name = ".config/opencode/skills/${name}";
                value = {
                  source = skill;
                  recursive = true;
                };
              })
              skills
            ))

            # Write subagents as markdown files under agents/ dir.
            (mkIf (builtins.isAttrs subagents && subagents != {}) (
              mapAttrs' (name: value: {
                name = ".config/opencode/agents/${name}.md";
                value = {
                  text =
                    if builtins.isPath value
                    then builtins.readFile value
                    else value;
                };
              })
              subagents
            ))

            # If subagents is a bare path (directory), symlink the whole tree.
            (mkIf (!builtins.isAttrs subagents && subagents != null && subagents != {}) {
              ".config/opencode/agents".source = subagents;
            })
          ];
        };
      }

      # ── Secrets variant (sops + wrapped binaries) ──
      (mkIf (options ? sops && allSecrets != []) {
        sops.secrets = genAttrs allSecrets (_: {});

        home.packages = with pkgs; [
          (symlinkJoin {
            name = "${cfg.package.name}-wrapped";
            paths = [cfg.package] ++ optional cfg.enableDesktop pkgs.opencode-desktop;
            buildInputs = [makeWrapper];
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
          })
        ];
      })
    ]);
  }
