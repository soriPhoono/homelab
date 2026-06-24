{
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  cfg = config.userapps.development.agents.hermes;
  shared = config.userapps.development.agents.agentics or {};

  inherit
    (lib)
    mkIf
    mkMerge
    mkEnableOption
    mkOption
    mkDefault
    types
    mapAttrs'
    mapAttrsToList
    genAttrs
    concatStringsSep
    baseNameOf
    ;

  # Merge shared agentics MCP servers with per-agent overrides (per-agent wins)
  mcpServers = {
    stdio = (shared.mcpServers.stdio or {}) // cfg.mcpServers.stdio;
    http = (shared.mcpServers.http or {}) // cfg.mcpServers.http;
  };
  skills = (shared.skills or {}) // cfg.skills;
  agentContext =
    if cfg.context != ""
    then cfg.context
    else shared.context or "";

  soulContent =
    if cfg.soul != ""
    then cfg.soul
    else agentContext;

  yamlFormat = pkgs.formats.yaml {};

  # Static list of secrets that hermes needs in its .env file.
  # Used by sops.templates (cannot reference allSecrets — circular dep).
  hermesSecrets = [
    "api/OPENROUTER_API_KEY"
    "api/EXA_API_KEY"
    "api/CONTEXT7_API_KEY"
    "api/GITHUB_API_KEY"
    "api/OPENCODE_API_KEY"
    "hermes/api_server_key"
    "hermes/dashboard_username"
    "hermes/dashboard_password"
  ];

  # Translate agentics MCP server to hermes-native mcp_servers format.
  # Secrets become $ENV_VAR references that hermes resolves from .env at runtime.
  translateMcpServer = _name: srv:
    if (srv ? "url" && srv ? "headers")
    then {
      inherit (srv) url;
      headers = lib.mapAttrs (
        _: val:
          if val ? "secret"
          then "${val.prefix or ""}$${val.name or (baseNameOf val.secret)}${val.suffix or ""}"
          else val
      ) (srv.headers or {});
    }
    else {
      inherit (srv) command;
      args = srv.args or [];
      env = lib.mapAttrs (
        _: val:
          if val ? "secret"
          then "$${val.name or (baseNameOf val.secret)}"
          else val
      ) (srv.env or {});
    };

  # ---- Main hermes config.yaml content ----
  hermesConfig = {
    terminal = {backend = "local";};
    agent = {
      max_turns = 60;
      reasoning_effort = "medium";
    };
    display = {tool_progress = "all";};
    mcp_servers = builtins.mapAttrs translateMcpServer (mcpServers.stdio // mcpServers.http);
  };

  # ---- SOUL.md generator ----
  createSoul = ctx: ''
    # Hermes Agent Runtime Context

    This file provides machine-level and user-level context for the Hermes agent.
    It is sourced by the hermes gateway and all profiles unless overridden.

    ${ctx}
  '';

  # ---- Profile config generator ----
  mkProfileConfig = _name: profile:
    {
      model =
        if profile.model != null
        then {default = profile.model;}
        else {};
      mcp_servers =
        if profile.mcpServers != null
        then
          builtins.mapAttrs translateMcpServer (
            (profile.mcpServers.stdio or {}) // (profile.mcpServers.http or {})
          )
        else {};
    }
    // profile.settings;

  mkProfileSoul = name: profile: let
    desc =
      if profile.soul == ""
      then "You are the \"${name}\" profile of a hermes agent."
      else if builtins.typeOf profile.soul == "path"
      then builtins.readFile profile.soul
      else profile.soul;
  in ''
    # Profile: ${name}
    ${profile.description}
    ${desc}
  '';
  # ---- .env builder ----
in
  with lib; {
    options.userapps.development.agents.hermes = homelab.agentics.mkAgent {
      name = "hermes";
      package = pkgs.emptyFile;
      extraOptions = {
        profiles = mkOption {
          type = types.attrsOf (types.submodule {
            options = {
              enable = mkEnableOption "this hermes profile";
              description = mkOption {
                type = types.str;
                default = "";
                description = ''
                  Description used by the kanban orchestrator to route tasks
                  based on profile capability.
                '';
              };
              model = mkOption {
                type = types.nullOr types.str;
                default = null;
                example = "anthropic/claude-sonnet-4";
                description = "Default model for this profile.";
              };
              soul = mkOption {
                type = with types; oneOf [str path];
                default = "";
                description = "Profile-specific SOUL.md content.";
              };
              skills = mkOption {
                type = types.attrsOf types.package;
                default = {};
                description = "Profile-specific skills.";
              };
              mcpServers = mkOption {
                type = types.nullOr (types.submodule {
                  options = {
                    stdio = mkOption {
                      type = types.attrsOf types.attrs;
                      default = {};
                      description = "Profile-level stdio MCP servers.";
                    };
                    http = mkOption {
                      type = types.attrsOf types.attrs;
                      default = {};
                      description = "Profile-level HTTP MCP servers.";
                    };
                  };
                });
                default = null;
                description = "Profile-level MCP servers (overrides global).";
              };
              settings = mkOption {
                type = types.attrs;
                default = {};
                description = "Additional profile-specific config.yaml settings.";
              };
            };
          });
          default = {};
          description = "Per-profile hermes agent configuration.";
        };

        defaultProfile = mkOption {
          type = types.str;
          default = "default";
          description = "Default active profile name.";
        };

        settings = mkOption {
          type = types.attrs;
          default = {};
          description = "Top-level config.yaml settings merged on top of auto-generated defaults.";
        };

        soul = mkOption {
          type = with types; oneOf [str path];
          default = "";
          description = "Hermes agent personality / SOUL.md content. Falls back to shared agentics.context if empty.";
        };

        user = mkOption {
          type = with types; oneOf [str path];
          default = "";
          description = "User-level context for USER.md. Separate from SOUL.md — this is about you, not the agent.";
        };
      };
    };

    config = mkIf cfg.enable (mkMerge [
      # Default empty context
      {userapps.development.agents.hermes.context = mkDefault "";}

      # Default secrets for hermes .env — user can override
      {
        userapps.development.agents.hermes.secrets = mkDefault [
          "api/OPENROUTER_API_KEY"
          "api/EXA_API_KEY"
          "api/CONTEXT7_API_KEY"
          "api/GITHUB_API_KEY"
          "api/OPENCODE_API_KEY"
          "hermes/api_server_key"
          "hermes/dashboard_username"
          "hermes/dashboard_password"
        ];
      }

      # ── Base config — write ~/.hermes/ files ──
      {
        home.file = mkMerge ([
            # Main config.yaml
            {
              ".hermes/config.yaml".source = yamlFormat.generate "hermes-config" (
                hermesConfig // cfg.settings
              );
            }

            # SOUL.md
            (mkIf (soulContent != "") (
              if builtins.typeOf soulContent == "path"
              then {
                ".hermes/SOUL.md".text = createSoul (builtins.readFile soulContent);
              }
              else {
                ".hermes/SOUL.md".text = createSoul soulContent;
              }
            ))

            # USER.md
            (mkIf (cfg.user != "") (
              if builtins.typeOf cfg.user == "path"
              then {
                ".hermes/USER.md".text = "# User Context\n\n${builtins.readFile cfg.user}";
              }
              else {
                ".hermes/USER.md".text = "# User Context\n\n${cfg.user}";
              }
            ))

            # Global skills symlinks
            (mkIf (skills != {}) (
              mapAttrs' (name: skill: {
                name = ".hermes/skills/${name}";
                value = {
                  source = skill;
                  recursive = true;
                };
              })
              skills
            ))
          ]
          # ── Profile directories ──
          ++ mapAttrsToList (name: profile:
            mkIf profile.enable (mkMerge [
              {
                ".hermes/profiles/${name}/config.yaml".source = yamlFormat.generate "hermes-profile-${name}-config" (mkProfileConfig name profile);
              }
              {
                ".hermes/profiles/${name}/profile.yaml".source = yamlFormat.generate "hermes-profile-${name}-meta" {
                  inherit (profile) description;
                  inherit name;
                };
              }
              {
                ".hermes/profiles/${name}/SOUL.md".text = mkProfileSoul name profile;
              }
              (mkIf (profile.skills != {}) (
                mapAttrs' (skillName: skill: {
                  name = ".hermes/profiles/${name}/skills/${skillName}";
                  value = {
                    source = skill;
                    recursive = true;
                  };
                })
                profile.skills
              ))
            ]))
          cfg.profiles);
      }

      # ── Secrets variant (sops) ──
      (mkIf (options ? sops) {
        sops.secrets = genAttrs hermesSecrets (_: {});

        sops.templates."hermes/dotenv" = {
          mode = "0600";
          path = "${config.home.homeDirectory}/.hermes/.env";
          content = ''
            # Hermes Agent environment variables
            # Managed by home-manager + sops-nix — do not edit manually
            ${concatStringsSep "\n" (
              map (secret: "${baseNameOf secret}=${config.sops.placeholder.${secret}}") hermesSecrets
            )}
          '';
        };
      })
    ]);
  }
