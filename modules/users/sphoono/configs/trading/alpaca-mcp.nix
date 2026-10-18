{ lib, den, ... }: {
  den.aspects.sphoono.trading = {
    includes = [
      den.aspects.sphoono.development.claude
    ];
    homeManager = { pkgs, config, ... }: {
      # Alpaca's MCP server for Claude Code, against the paper account.
      # Not in nixpkgs, so uvx fetches the pinned PyPI release. The keys
      # come from sops and are exported to the server alone; putting them
      # in `env` would write them to the store.
      programs.claude-code.mcpServers.alpaca = {
        command = "${pkgs.writeShellScript "alpaca-mcp" ''
          ALPACA_API_KEY="$(cat ${config.sops.secrets."api/alpaca-paper-key-id".path})"
          ALPACA_SECRET_KEY="$(cat ${config.sops.secrets."api/alpaca-paper-secret-key".path})"
          export ALPACA_API_KEY ALPACA_SECRET_KEY
          exec ${lib.getExe' pkgs.uv "uvx"} alpaca-mcp-server@2.3.2
        ''}";
        env = {
          ALPACA_PAPER_TRADE = "true";
          # No "trading" toolset: the paper account is shared with the n8n
          # Alpaca bot, whose risk gate reads the account's positions and
          # orders. Add it to let Claude place orders. "account" still
          # carries update_account_config (shorting, fractional trading).
          ALPACA_TOOLSETS = "account,assets,stock-data,crypto-data,options-data,news,corporate-actions,watchlists";
        };
      };

      sops.secrets = {
        "api/alpaca-paper-key-id".mode = "0400";
        "api/alpaca-paper-secret-key".mode = "0400";
      };
    };
  };
}
