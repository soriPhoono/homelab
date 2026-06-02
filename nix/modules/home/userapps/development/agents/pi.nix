# {
#   lib,
#   pkgs,
#   config,
#   options,
#   ...
# }: let
#   agentsCfg = config.userapps.development.agentics.agents;
#   cfg = config.userapps.development.agents.pi;
#   # Resolve flavor-specific settings.
#   flavorPkg =
#     if cfg.flavor == "omp"
#     then pkgs.omp
#     else pkgs.pi;
#   flavorBinName =
#     if cfg.flavor == "omp"
#     then "omp"
#     else "pi";
#   flavorConfigDir =
#     if cfg.flavor == "omp"
#     then ".omp"
#     else ".pi";
#   # Auto-discover MCP server secrets from the agentics/agent MCP config.
#   mcpSecrets = let
#     extractSecretNames = attrs:
#       lib.filter (v: v != null) (
#         lib.mapAttrsToList (
#           _: val:
#             if builtins.isAttrs val && val ? "secret"
#             then val.secret
#             else null
#         )
#         attrs
#       );
#   in
#     lib.flatten (
#       lib.mapAttrsToList (_: srv: extractSecretNames (srv.env or {} // srv.headers or {})) agentsCfg.mcp
#     );
#   allSecrets = lib.unique (cfg.secrets ++ mcpSecrets);
#   # Translate agentics MCP server config to standard MCP config format
#   # (compatible with pi-mcp-extension and omp's built-in MCP).
#   mcpServerConfig = let
#     hasAnySecret = attrs: lib.any (v: builtins.isAttrs v && v ? "secret") (lib.attrValues attrs);
#     renderEnvValue = value:
#       if value ? "secret"
#       then
#         "$"
#         + (
#           if value.environmentVariable or null != null
#           then value.environmentVariable
#           else baseNameOf value.secret
#         )
#       else value;
#     renderHeaderValue = value:
#       if value ? "secret"
#       then
#         (
#           if value.prefix or null != null
#           then value.prefix
#           else ""
#         )
#         + "$"
#         + (
#           if value.environmentVariable or null != null
#           then value.environmentVariable
#           else baseNameOf value.secret
#         )
#       else value;
#     renderServer = name: srv:
#       if srv.transport == "http" && hasAnySecret (srv.headers or {})
#       then let
#         wrapperName = "${flavorBinName}-mcp-proxy-${name}";
#         headerFlags = lib.concatStringsSep " \\\n        " (
#           lib.mapAttrsToList (
#             hname: val:
#               if val ? "secret"
#               then "--headers '${hname}' \"${renderHeaderValue val}\""
#               else "--headers '${hname}' '${val}'"
#           ) (srv.headers or {})
#         );
#         wrapper = pkgs.writeShellScriptBin wrapperName ''
#           exec ${pkgs.mcp-proxy}/bin/mcp-proxy \
#             --transport streamablehttp \
#             ${headerFlags} \
#             '${srv.url}'
#         '';
#       in {
#         command = "${wrapper}/bin/${wrapperName}";
#         args = [];
#         lifecycle = "eager";
#         transport = "stdio";
#       }
#       else
#         {
#           inherit (srv) transport;
#           lifecycle = "eager";
#         }
#         // (
#           if srv.transport == "stdio"
#           then {
#             inherit (srv) command;
#             args = srv.args or [];
#           }
#           else {inherit (srv) url;}
#         )
#         // (lib.optionalAttrs (srv.env or {} != {}) {
#           env = lib.mapAttrs (_: renderEnvValue) srv.env;
#         });
#   in {
#     mcpServers = builtins.mapAttrs renderServer agentsCfg.mcp;
#   };
#   hasMcpServers = agentsCfg.mcp != {};
#   # Split the agentics context into system vs user+operational parts.
#   # System context goes into system.md; everything else stays in AGENTS.md.
#   # Reconstruct AGENTS.md content without the system section.
#   # We build it from the user context (if any) plus the agent operational
#   # guidance that comes after "## User Identity" in the full context.
# in
#   with lib; {
#     config = mkIf cfg.enable (mkMerge [
#       {
#         home.file = mkMerge [
#
#           # Wire MCP servers.
#           # Vanilla pi uses the pi-mcp-extension package; omp has MCP built-in.
#           # Both read the same config format.
#           (mkIf hasMcpServers {
#             "${flavorConfigDir}/agent/mcp.json".text = builtins.toJSON mcpServerConfig;
#           })
#
#           # Write packages.json — auto-add pi-mcp-extension for vanilla pi
#           # when MCP servers are configured.
#           (mkIf (cfg.packages != [] || (hasMcpServers && cfg.flavor == "pi")) {
#             "${flavorConfigDir}/packages.json".text = builtins.toJSON {
#               packages =
#                 cfg.packages ++ optionals (hasMcpServers && cfg.flavor == "pi") ["npm:pi-mcp-extension"];
#             };
#           })
#         ];
#       }
#     ]);
#   }
{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.development.agents.pi;

  createContext = ctx: ''
    # Pi Runtime Context

    This file provides machine-level and user-level context for the Pi coding agent.
    Project-level repository guidance stays in the repository root
    `AGENTS.md`.

    ${ctx}
  '';

  # Translate agentics MCP server config to standard MCP config format
  # (compatible with pi-mcp-extension and omp's built-in MCP).
  mcpServerConfig = let
    renderEnvValue = value:
      if value ? "secret"
      then "$" + value.name
      else value;

    renderHeaderValue = value:
      if value ? "secret"
      then
        (
          if value.prefix or null != null
          then value.prefix
          else ""
        )
        + "$"
        + value.name
      else value;

    renderServer = name: srv:
      {
        transport = "stdio";
        lifecycle = "eager";
      }
      // (
        if (srv ? "url" && srv ? "headers")
        then let
          wrapperName = "pi-mcp-proxy-${name}";
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
        }
        else
          {
            inherit (srv) command args;
          }
          // (lib.optionalAttrs (srv.env or {} != {}) {
            env = lib.mapAttrs (_: renderEnvValue) srv.env;
          })
      );
  in {
    mcpServers = builtins.mapAttrs renderServer (cfg.mcpServers.stdio // cfg.mcpServers.http);
  };

  hasMcpServers = cfg.mcpServers.stdio != {} && cfg.mcpServers.http != {};
in
  with lib; {
    options.userapps.development.agents.pi = homelab.agentics.mkAgent {
      name = "pi";
      extraOptions = {
        packages = mkOption {
          type = with types; listOf str;
          default =
            if cfg.mcpServers != {}
            then [
              "npm:pi-mcp-extension"
            ]
            else [];
          description = ''
            The packages to install for the pi agent.
          '';
        };
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        warnings =
          optionals (!(options ? sops) && cfg.secrets != [])
          "Failed to install ${flavorBinName} as it was requested with secrets embedment, which requires sops, which is currently disabled";

        home.packages = [
          pkgs.pi
        ];

        home.file = mkMerge [
          (mkMerge [
            (mkIf (typeOf cfg.context.system == "path") {
              "${config.home.homeDirectory}/.pi/SYSTEM.md".text = createContext (readFile cfg.context.system);
            })
            (mkIf (typeOf cfg.context.system == "str") {
              "${config.home.homeDirectory}/.pi/SYSTEM.md".text = createContext cfg.context.system;
            })
            (mkIf (typeOf cfg.context.user == "path") {
              "${config.home.homeDirectory}/.pi/AGENTS.md".text = readFile cfg.context.user;
            })
            (mkIf (typeOf cfg.context.user == "str") {
              "${config.home.homeDirectory}/.pi/AGENTS.md".text = cfg.context.user;
            })
          ])
          # Link skills from the shared agentics skills registry.
          (mkIf (cfg.skills != {}) (
            lib.mapAttrs' (
              name: skill:
                mkMerge [
                  (mkIf (typeOf skill == "package") {
                    name = "${config.home.homeDirectory}/.pi/skills/${name}";
                    value = {
                      source = skill;
                      recursive = true;
                    };
                  })
                  (mkIf (typeOf skill == "path") {
                    name = "${config.home.homeDirectory}/.pi/skills/${name}";
                    value = {
                      source = skill;
                      recursive = true;
                    };
                  })
                  (mkIf (typeOf skill == "str") {
                    name = "${config.home.homeDirectory}/.pi/skills/${name}";
                    value = {
                      text = skill;
                    };
                  })
                ]
            )
            cfg.skills
          ))
          # Wire MCP servers.
          # Vanilla pi uses the pi-mcp-extension package; omp has MCP built-in.
          # Both read the same config format.
          (mkIf hasMcpServers {
            "${flavorConfigDir}/agent/mcp.json".text = builtins.toJSON mcpServerConfig;
          })
        ];
      }
      (mkIf (options ? sops && cfg.secrets != []) {
        sops.secrets = genAttrs cfg.secrets (_: {});

        home.packages = with pkgs; [
          (symlinkJoin {
            name = "${cfg.package}-wrapped";
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
                cfg.secrets
              )}
                fi
              done
            '';
          })
        ];
      })
    ]);
  }
