# GitHub Copilot CLI home-manager module.
#
# Manages ~/.copilot/ config files and wraps the copilot binary
# for sops secret injection.
#
# Config directory: ~/.copilot/ (default, overridable via $COPILOT_HOME)
#
# Generated files:
#   settings.json           — user settings (model, renderMarkdown, etc.)
#   copilot-instructions.md — global context/instructions
#   mcp-config.json         — MCP server definitions (with wrapper scripts
#                             for servers needing secret env/headers)
#   skills/<name>/          — symlinked skill derivations
{
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  cfg = config.userapps.development.agents.github-copilot;

  # ---- Gather all secret names from MCP servers ----
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
      lib.mapAttrsToList (
        _name: srv:
          extractSecretNames (srv.env or {})
          ++ extractSecretNames (srv.headers or {})
      )
      cfg.mcpServers
    );

  allSecrets = lib.unique (cfg.secrets ++ mcpSecrets);

  # ---- Predicates for secret detection ----
  hasEnvSecret = srv:
    lib.any (v: builtins.isAttrs v && v ? "secret") (lib.attrValues (srv.env or {}));

  hasHeaderSecret = srv:
    lib.any (v: builtins.isAttrs v && v ? "secret") (lib.attrValues (srv.headers or {}));

  # ---- MCP server translation ----
  #
  # Converts homelab's MCP server config format to Copilot CLI's
  # mcp-config.json format.  Servers with secrets in env/headers
  # get wrapper scripts (writeShellScriptBin) that resolve the
  # secret at runtime from the environment (set by makeWrapper on
  # the copilot binary).
  translateMcpServer = name: srv:
    if (srv ? "url" && srv ? "headers")
    then
      # ── HTTP / SSE transport ──
      if hasHeaderSecret srv
      then
        # Headers contain secrets → wrap via mcp-proxy with runtime expansion
        let
          wrapperName = "copilot-mcp-proxy-${name}";
          mkHeaderFlag = hname: val:
            if val ? "secret"
            then "--headers '${hname}' \"\${${baseNameOf val.secret}}\""
            else "--headers '${hname}' '${lib.escapeShellArg val}'";
          headerFlags = lib.concatStringsSep " \\\n                " (
            lib.mapAttrsToList mkHeaderFlag (srv.headers or {})
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
          command = "${wrapper}/bin/${wrapperName}";
          args = [];
          tools = ["*"];
        }
      else {
        type =
          if srv.transport or "http" == "sse"
          then "sse"
          else "http";
        inherit (srv) url;
        headers = srv.headers or {};
        tools = ["*"];
      }
    else
      # ── Stdio transport ──
      if hasEnvSecret srv
      then
        # Env contains secrets → wrap via shell script that
        # re-exports the env vars (set by makeWrapper on copilot binary)
        # before exec-ing the actual MCP command.
        let
          wrapperName = "copilot-mcp-stdio-${name}";
          envExports = lib.concatStringsSep "\n" (
            lib.mapAttrsToList (
              envName: value:
                if value ? "secret"
                then "export ${baseNameOf value.secret}=\"\$${baseNameOf value.secret}\""
                else "export ${envName}=${lib.escapeShellArg value}"
            ) (srv.env or {})
          );
          argsStr = lib.concatStringsSep " " (map lib.escapeShellArg (srv.args or []));
          wrapper = pkgs.writeShellScriptBin wrapperName ''
            ${envExports}
            exec ${lib.escapeShellArg srv.command} ${argsStr}
          '';
        in {
          type = "local";
          command = "${wrapper}/bin/${wrapperName}";
          args = [];
          tools = ["*"];
        }
      else {
        type = "local";
        inherit (srv) command;
        args = srv.args or [];
        env = srv.env or {};
        tools = ["*"];
      };

  # ---- Context wrapper ----
  createContext = ctx: ''
    # GitHub Copilot CLI Runtime Context

    This file provides machine-level and user-level context for Copilot CLI.
    Project-level repository guidance stays in the repository root
    `AGENTS.md` and `.agents/AGENTS.md`.

    ${ctx}
  '';
in
  with lib; {
    options.userapps.development.agents.github-copilot = homelab.agentics.mkAgent {
      name = "github-copilot";
      package = pkgs.github-copilot-cli;
      extraOptions = {
        settings = mkOption {
          type = with types; attrs;
          default = {};
          description = ''
            Extra settings to merge into `settings.json` for Copilot CLI.
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
    };

    config = mkIf cfg.enable (mkMerge [
      # ── Base config (no secrets variant) ──
      {
        home.file = mkMerge [
          # settings.json
          {
            ".copilot/settings.json".text = builtins.toJSON (
              {
                model = mkDefault "claude-sonnet-4-5";
                renderMarkdown = mkDefault true;
                autoUpdate = mkDefault false;
              }
              // (cfg.userSettings or {})
              // cfg.settings
            );
          }

          # copilot-instructions.md (context / AGENTS.md equivalent)
          (mkIf (cfg.context != "") (
            if builtins.typeOf cfg.context == "path"
            then {
              ".copilot/copilot-instructions.md".text = createContext (builtins.readFile cfg.context);
            }
            else {
              ".copilot/copilot-instructions.md".text = createContext cfg.context;
            }
          ))

          # mcp-config.json (MCP server definitions)
          (mkIf (cfg.mcpServers != {}) {
            ".copilot/mcp-config.json".text = builtins.toJSON {
              mcpServers = builtins.mapAttrs translateMcpServer cfg.mcpServers;
            };
          })

          # skills/ (symlinked skill derivations)
          (mkIf (cfg.skills != {}) (
            mapAttrs' (name: skill: {
              name = ".copilot/skills/${name}";
              value = {
                source = skill;
                recursive = true;
              };
            })
            cfg.skills
          ))
        ];
      }

      # ── Secrets variant (sops + wrapped copilot binary) ──
      (mkIf (options ? sops && allSecrets != []) {
        sops.secrets = genAttrs allSecrets (_: {});

        home.packages = with pkgs; [
          (symlinkJoin {
            name = "${cfg.package.name}-wrapped";
            paths = [cfg.package];
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
