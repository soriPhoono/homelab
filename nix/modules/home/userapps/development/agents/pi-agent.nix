{
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  agentsCfg = config.userapps.development.agentics.agents;
  cfg = config.userapps.development.agents.pi-agent;

  # Resolve flavor-specific settings.
  flavorPkg =
    if cfg.flavor == "omp"
    then pkgs.omp
    else pkgs.pi;

  flavorBinName =
    if cfg.flavor == "omp"
    then "omp"
    else "pi";

  flavorConfigDir =
    if cfg.flavor == "omp"
    then ".omp"
    else ".pi";

  # Auto-discover MCP server secrets from the agentics/agent MCP config.
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

  # Translate agentics MCP server config to standard MCP config format
  # (compatible with pi-mcp-extension and omp's built-in MCP).
  mcpServerConfig = let
    hasAnySecret = attrs:
      lib.any (v: builtins.isAttrs v && v ? "secret")
      (lib.attrValues attrs);

    renderEnvValue = value:
      if value ? "secret"
      then "$" + value.environmentVariable
      else value;

    renderHeaderValue = value:
      if value ? "secret"
      then (value.prefix or "") + "$" + value.environmentVariable
      else value;

    renderServer = name: srv:
      if srv.transport == "http" && hasAnySecret (srv.headers or {})
      then let
        wrapperName = "omp-mcp-proxy-${name}";
        headerFlags = lib.concatStringsSep " \\\n        " (
          lib.mapAttrsToList (
            hname: val:
              if val ? "secret"
              then "--headers '${hname}' \"${renderHeaderValue val}\""
              else "--headers '${hname}' '${val}'"
          ) (srv.headers or {})
        );
        wrapper = pkgs.writeShellScriptBin wrapperName ''
          exec ${pkgs.mcp-proxy}/bin/mcp-proxy \
            --transport streamablehttp \
            ${headerFlags} \
            '${srv.url}'
        '';
      in {
        command = "${wrapper}/bin/${wrapperName}";
        args = [];
        lifecycle = "eager";
        transport = "stdio";
      }
      else
        {
          inherit (srv) transport;
          lifecycle = "eager";
        }
        // (
          if srv.transport == "stdio"
          then {
            inherit (srv) command;
            args = srv.args or [];
          }
          else {inherit (srv) url;}
        )
        // (lib.optionalAttrs (srv.env or {} != {}) {
          env = lib.mapAttrs (_: renderEnvValue) srv.env;
        });
  in {
    mcpServers = builtins.mapAttrs renderServer agentsCfg.mcp;
  };

  hasMcpServers = agentsCfg.mcp != {};
  # Split the agentics context into system vs user+operational parts.
  # System context goes into system.md; everything else stays in AGENTS.md.
  # Reconstruct AGENTS.md content without the system section.
  # We build it from the user context (if any) plus the agent operational
  # guidance that comes after "## User Identity" in the full context.
in
  with lib; {
    options.userapps.development.agents.pi-agent = {
      enable = mkEnableOption ''
        Enable the pi/omp coding agent and write system prompt context
        to `~/.pi/system.md` (or `~/.omp/system.md` for omp flavor) for
        automatic discovery at startup.
      '';

      flavor = mkOption {
        type = types.enum [
          "pi"
          "omp"
        ];
        default = "pi";
        description = ''
          Which agent distribution to use.

          - `"pi"`: Vanilla Pi coding agent (`@earendil-works/pi-coding-agent`).
            MCP tool support requires the `pi-mcp-extension` package, auto-installed
            when MCP servers are configured.
          - `"omp"`: oh-my-pi fork with batteries-included features (native MCP,
            LSP, browser, subagents, etc.). MCP support is built-in.
        '';
      };

      secrets = mkOption {
        type = with types; listOf str;
        default = [];
        description = ''
          List of secrets to be injected into the agent's runtime environment. Each
          secret will be defined in `config.sops.secrets` and made available as an
          environment variable with the same name as the secret key.

          Typical provider secrets include:
          - api/ANTHROPIC_API_KEY
          - api/OPENAI_API_KEY
          - api/OPENROUTER_API_KEY
          - api/GOOGLE_API_KEY
        '';
        example = ["api/ANTHROPIC_API_KEY"];
      };

      packages = mkOption {
        type = with types; listOf str;
        default = [];
        description = ''
          Pi/omp package names to install from npm or git references. These are
          added to `packages.json` in the agent's config directory so the agent
          loads them at startup.

          Packages can include extensions, skills, prompt templates, and themes.
          e.g.: [ "github:user/pi-some-package" ]
        '';
        example = ["github:user/pi-some-package"];
      };

      settings = mkOption {
        type = with types; attrs;
        default = {};
        description = ''
          Extra settings to write into the agent's config file. Merged on top of
          any auto-configured values.

          See the agent's documentation for available configuration keys.
        '';
        example = {};
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        warnings =
          optionals (!(options ? sops) && cfg.secrets != [])
          "Failed to install ${flavorBinName} as it was requested with secrets embedment, which requires sops, which is currently disabled";

        home.packages = with pkgs;
          mkIf (allSecrets == []) [
            flavorPkg
          ];

        home.file = mkMerge [
          {
            # System prompt context — everything the agent needs to know about
            # the system, user, and operational expectations.
            "${flavorConfigDir}/SYSTEM.md".text = ''
              # ${flavorBinName} Runtime Context

              This file provides machine-level and user-level context for the ${flavorBinName} coding agent.
              Project-level repository guidance stays in the repository root
              `AGENTS.md` and `.agents/AGENTS.md`.

              ${agentsCfg.context {}}
            '';
          }

          # Wire MCP servers.
          # Vanilla pi uses the pi-mcp-extension package; omp has MCP built-in.
          # Both read the same config format.
          (mkIf hasMcpServers {
            "${flavorConfigDir}/agent/mcp.json".text = builtins.toJSON mcpServerConfig;
          })

          # Link skills from the shared agentics skills registry.
          (mkIf (agentsCfg.skills != {}) (
            lib.mapAttrs' (name: pkg: {
              name = "${flavorConfigDir}/skills/${name}";
              value = {
                source = pkg;
                recursive = true;
              };
            })
            agentsCfg.skills
          ))

          # Write packages.json — auto-add pi-mcp-extension for vanilla pi
          # when MCP servers are configured.
          (mkIf (cfg.packages != [] || (hasMcpServers && cfg.flavor == "pi")) {
            "${flavorConfigDir}/packages.json".text = builtins.toJSON {
              packages =
                cfg.packages ++ optionals (hasMcpServers && cfg.flavor == "pi") ["npm:pi-mcp-extension"];
            };
          })
        ];
      }
      (mkIf (options ? sops && allSecrets != []) {
        sops.secrets = genAttrs allSecrets (_: {});

        home.packages = with pkgs; [
          (symlinkJoin {
            name = "${flavorBinName}-wrapped";
            paths = [flavorPkg];
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
