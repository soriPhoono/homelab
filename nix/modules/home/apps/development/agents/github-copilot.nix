# GitHub Copilot CLI home-manager module.
#
# Bridges our homelab agent config (homelab.agentics.mkAgent) to the
# upstream programs.github-copilot-cli home-manager module.
#
# What the upstream handles:
#   settings, context, mcpServers, skills, agents, lspServers,
#   configDir (with COPILOT_HOME auto-export), package install
#
# What we keep custom:
#   translateMcpServer — generates writeShellScriptBin wrappers for
#     MCP servers with sops secret env/headers, resolving at runtime
#   Secret injection — wraps the copilot binary via symlinkJoin +
#     makeWrapper --run to export sops secrets into the environment
{
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  cfg = config.apps.development.agents.github-copilot;

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
  # Converts homelab's MCP server config format to the format expected
  # by programs.github-copilot-cli.mcpServers.
  #
  # Servers with secrets in env/headers get wrapper scripts that resolve
  # at runtime from the environment (set by makeWrapper on the copilot
  # binary).
  translateMcpServer = name: srv:
    if (srv.url != null)
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
        # Env contains secrets → wrap via shell script that re-exports
        # the env vars (set by makeWrapper on copilot binary) before
        # exec-ing the actual MCP command.
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

  # ---- Settings defaults (merged into upstream config.json) ----
  defaultSettings = {
    model = lib.mkDefault "claude-sonnet-4-5";
    renderMarkdown = lib.mkDefault true;
    autoUpdate = lib.mkDefault false;
  };
in
  with lib; {
    options.apps.development.agents.github-copilot = homelab.agentics.mkAgent {
      name = "github-copilot";
      package = pkgs.github-copilot-cli;
      extraOptions = {
        settings = mkOption {
          type = with types; attrs;
          default = {};
          description = ''
            Extra settings to merge into `config.json` for Copilot CLI.
            Merged on top of base defaults (model, renderMarkdown, autoUpdate)
            and any userSettings.

            See https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-config-dir-reference
            for available configuration keys.
          '';
          example = {
            model = "claude-sonnet-4-5";
            theme = "dim";
          };
        };
      };
    };

    config = mkIf cfg.enable (mkMerge [
      # ── Base config: delegate to upstream HM module ──
      {
        programs.github-copilot-cli = {
          enable = true;
          package = mkDefault cfg.package;

          settings = defaultSettings // (cfg.userSettings or {}) // cfg.settings;

          context =
            cfg.documents."copilot-instructions.md" or "";

          mcpServers = builtins.mapAttrs translateMcpServer cfg.mcpServers;

          skills = mapAttrs (_name: pkg: pkg) cfg.skills;
        };
      }

      # ── Secrets variant (sops + wrapped copilot binary) ──
      (mkIf (options ? sops && allSecrets != []) {
        sops.secrets = genAttrs allSecrets (_: {});

        programs.github-copilot-cli.package = let
          pkg = cfg.package;
        in
          with pkgs;
            symlinkJoin {
              name = "${pkg.name}-wrapped";
              paths = [pkg];
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
            };
      })
    ]);
  }
