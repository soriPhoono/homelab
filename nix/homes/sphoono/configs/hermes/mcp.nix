{
  lib,
  pkgs,
  config,
  ...
}:
with lib; {
  config = mkMerge [
    {
      userapps.development.agents.hermes = {
        mcpServers = {
          obsidian = {
            command = "${pkgs.nodejs}/bin/npx";
            args = [
              "-y"
              "@bitbonsai/mcpvault@latest"
              "${config.home.homeDirectory}/Nextcloud/Vault"
            ];
          };

          nixos = {
            command = "uvx";
            args = [
              "mcp-nixos"
            ];
          };
        };
      };
    }
  ];
}
