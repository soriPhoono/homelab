# TODO: Finish opencode configuration
{
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  cfg = config.userapps.development.agents.opencode;
in
  with lib; {
    options.userapps.development.agents.opencode = let
      jsonFormat = pkgs.formats.json {};
    in {
      enable = mkEnableOption "Enable OpenCode AI agent";

      secrets = mkOption {
        type = with types; listOf str;
        description = "Secret names to load in from sops for opencode functionality";
        default = [];
      };

      settings = mkOption {
        inherit (jsonFormat) type;
        description = "OpenCode settings";
        default = {};
      };

      mcpServers = mkOption {
        inherit (jsonFormat) type;
        description = "MCP servers to connect opencode to";
        default = {};
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        programs.opencode = {
          enable = true;
          enableMcpIntegration = true;

          settings =
            {
              mcp = cfg.mcpServers;
            }
            // cfg.settings;
        };
      }
      (mkIf (options ? sops && cfg.secrets != []) {
        sops.secrets = genAttrs cfg.secrets (_: {});

        programs.opencode.package = pkgs.symlinkJoin {
          name = "opencode-wrapped";
          paths = [pkgs.opencode];
          buildInputs = [pkgs.makeWrapper];

          postBuild = ''
            for bin in $out/bin/*; do
              # Ensure it is actually a file and is executable before wrapping
              if [ -f "$bin" ] && [ -x "$bin" ]; then
                # Pass ALL --run commands into a SINGLE wrapProgram invocation
                wrapProgram "$bin" \
                  ${concatStringsSep " \\\n                  " (
              map
              (secret: "--run '[ -f ${config.sops.secrets.${secret}.path} ] && export ${baseNameOf secret}=\"$(cat ${config.sops.secrets.${secret}.path})\"'")
              cfg.secrets
            )}
              fi
            done
          '';
        };
      })
    ]);
  }
