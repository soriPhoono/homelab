{
  lib,
  pkgs,
  config,
  inputs,
  ...
}: let
  cfg = config.userapps.development.agents.mcp-servers;
  geminiCfg = config.userapps.development.agents.gemini;
  claudeCfg = config.userapps.development.agents.claude;

  # Helper to format the MCP servers for JSON output
  mcpServersJson = builtins.toJSON (
    lib.mapAttrs (_: srv:
      {
        command = "${pkgs.nodejs}/bin/npx";
        args = ["-y" "-q" srv.command] ++ srv.args;
      }
      // lib.optionalAttrs (srv.env != {}) {inherit (srv) env;})
    cfg
  );

  # Script to update settings files
  updateScript = pkgs.writeShellScriptBin "mcp-config-updater" ''
    set -euo pipefail

    # Path to jq
    JQ="${pkgs.jq}/bin/jq"

    # JSON content from Nix
    MCP_SERVERS='${mcpServersJson}'

    update_config() {
      local file="$1"
      local dir=$(dirname "$file")

      if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
      fi

      if [ ! -f "$file" ]; then
        echo "{}" > "$file"
      fi

      # Update mcpServers key, preserving other settings
      # Use a temporary file to ensure atomicity and avoid truncating on read
      tmp=$(mktemp)
      if $JQ --argjson servers "$MCP_SERVERS" '.mcpServers = $servers' "$file" > "$tmp"; then
        mv "$tmp" "$file"
        chmod 600 "$file"
        echo "Updated $file"
      else
        echo "Failed to update $file"
        rm "$tmp"
        exit 1
      fi
    }

    # Update Gemini if enabled
    ${lib.optionalString geminiCfg.enable ''
      update_config "$HOME/.gemini/settings.json"
    ''}

    # Update Claude if enabled
    ${lib.optionalString claudeCfg.enable ''
      update_config "$HOME/.claude-code/settings.json"
    ''}
  '';
in
  with lib; {
    options.userapps.development.agents.mcp-servers = mkOption {
      type = with types;
        attrsOf (submodule {
          options = {
            command = mkOption {
              type = str;
              description = "The command to run";
            };
            args = mkOption {
              type = listOf str;
              default = [];
              description = "The arguments to pass to the command";
            };
            env = mkOption {
              type = attrsOf str;
              default = {};
              description = "The environment variables to set";
            };
          };
        });
      default = let
        mcps = inputs.mcps.packages.${pkgs.system};
      in {
        "git" = {
          command = "${mcps.mcp-servers}/bin/mcp-server-git";
        };
        "filesystem" = {
          command = "${mcps.mcp-servers}/bin/mcp-server-filesystem";
          args = ["/home/soriphoono"];
        };
        "fetch" = {
          command = "${mcps.mcp-servers}/bin/mcp-server-fetch";
        };
        "memory" = {
          command = "${mcps.mcp-servers}/bin/mcp-server-memory";
        };
        "sequential-thinking" = {
          command = "${mcps.mcp-servers}/bin/mcp-server-sequentialthinking";
        };
        "time" = {
          command = "${mcps.mcp-servers}/bin/mcp-server-time";
        };
        "ast-grep" = {
          command = "${mcps.ast-grep-mcp}/bin/ast-grep-mcp";
        };
        "obsidian" = {
          command = "${mcps.mcp-obsidian}/bin/mcp-obsidian";
          args = ["/home/soriphoono/Documents/Vault"];
        };
        "grafana" = {
          command = "${mcps.mcp-grafana}/bin/mcp-grafana";
        };
        "asana" = {
          command = "${mcps.mcp-server-asana}/bin/mcp-server-asana";
        };
        # "github" - mcp-server-github not found in mcps.nix
      };
      description = "The MCP servers to run";
    };

    config = {
      # Define the systemd service
      systemd.user.services.mcp-config-loader = {
        Unit = {
          Description = "Update MCP server configuration in agent settings";
          After = ["graphical-session.target"];
          PartOf = ["graphical-session.target"];
        };

        Service = {
          Type = "oneshot";
          ExecStart = "${updateScript}/bin/mcp-config-updater";
          RemainAfterExit = true;
        };

        Install = {
          WantedBy = ["graphical-session.target"];
        };
      };
    };
  }
