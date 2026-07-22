{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.apps.development.agents.antigravity;

  # Translate agent MCP servers into Antigravity userMcp format
  mcpUserMcp = {
    mcpServers =
      builtins.mapAttrs (
        name: srv:
          if (srv.url != null && srv.command == null)
          then {
            serverUrl = srv.url;
            headers =
              lib.mapAttrs
              (_name: value:
                if (builtins.isAttrs value && value ? "secret")
                then
                  (
                    if value.prefix != null
                    then value.prefix
                    else ""
                  )
                  + config.sops.placeholder.${value.secret}
                  + (
                    if value.suffix != null
                    then value.suffix
                    else ""
                  )
                else value)
              (
                if srv.headers != null
                then srv.headers
                else {}
              );
          }
          else if (srv.command != null && srv.url == null)
          then {
            inherit (srv) command args;
            env =
              lib.mapAttrs
              (_name: value:
                if value ? "secret"
                then config.sops.placeholder.${value.secret}
                else value)
              (
                if srv.env != null
                then srv.env
                else {}
              );
          }
          else throw "MCP server ${name} must have either url or command"
      )
      cfg.mcpServers;
  };
in
  with lib; {
    options.apps.development.agents.antigravity = mkOption {
      type = types.submodule (_: {
        options = lib.homelab.development.mkAgent {
          name = "antigravity";
          package = pkgs.antigravity;
          extraOptions = {
            enableCli = mkEnableOption "Enable antigravity cli";
            enableDesktop = mkEnableOption "Enable antigravity desktop interface";

            desktopPackage = mkOption {
              type = types.package;
              default = pkgs.google-antigravity;
              description = "The package to use for the antigravity desktop interface.";
            };

            instructions = mkOption {
              type = types.nullOr (types.oneOf [types.path types.lines]);
              default = null;
              description = "Documents to be made available to the agent.";
            };
          };
        };
      });
    };

    config = mkIf cfg.enable (mkMerge [
      {
        sops = {
          secrets =
            genAttrs
            (flatten (mapAttrsToList (_name: srv:
              mapAttrsToList (_name: value: value.secret)
              (filterAttrs
                (_name: value: builtins.isAttrs value && value ? "secret")
                (
                  if srv.env != null
                  then srv.env
                  else if srv.headers != null
                  then srv.headers
                  else {}
                )))
            cfg.mcpServers))
            (_name: {});
          templates."gemini/mcp_config.json" = {
            path = "${config.home.homeDirectory}/.gemini/config/mcp_config.json";
            content = ''
              ${builtins.toJSON mcpUserMcp}
            '';
          };
        };

        # Wire agent context documents and skills into Antigravity IDE's
        # config directory. The IDE scans ~/.gemini/antigravity/ for global
        # agent config, and ~/.gemini/antigravity/skills/<name>/SKILL.md for
        # global skills.
        home.file =
          {
            ".gemini/GEMINI.md" = mkIf (cfg.instructions != null) (
              if builtins.isPath cfg.instructions
              then {source = cfg.instructions;}
              else {text = cfg.instructions;}
            );
          }
          # Agent skills — each is a package containing SKILL.md,
          # symlinked into Antigravity's global skills directory.
          // mapAttrs' (
            name: pkg:
              nameValuePair ".gemini/antigravity/skills/${name}" {
                source = pkg;
                recursive = true;
              }
          )
          cfg.skills;
      }
      (mkIf cfg.enableCli {
        programs.antigravity-cli = {
          enable = true;
        };
      })
      (mkIf cfg.enableDesktop {
        home.packages = [
          cfg.desktopPackage
        ];
      })
    ]);
  }
