{
  lib,
  pkgs,
  config,
  ...
}:
with lib; {
  config = mkMerge [
    {
      apps.development.agents.hermes = {
        mcpServers = {
          # ── Personal ───────────────────────────────────────────────────────
          "personal/obsidian" = {
            command = "${pkgs.nodejs}/bin/npx";
            args = [
              "-y"
              "@bitbonsai/mcpvault@latest"
              "${config.home.homeDirectory}/Nextcloud/Vault"
            ];
          };

          "personal/nixos" = {
            command = "${pkgs.uv}/bin/uvx";
            args = [
              "mcp-nixos"
            ];
          };

          "personal/sequential-thinking" = {
            command = "${pkgs.nodejs}/bin/npx";
            args = [
              "-y"
              "@modelcontextprotocol/server-sequential-thinking"
            ];
          };

          # ── Software dev ────────────────────────────────────────────────────
          "software-dev/github" = {
            command = "${pkgs.nodejs}/bin/npx";
            args = [
              "-y"
              "@modelcontextprotocol/server-github"
            ];
            env = {
              GITHUB_PERSONAL_ACCESS_TOKEN = {
                secret = "api/GITHUB_TOKEN";
              };
            };
          };

          "software-dev/database" = {
            command = "${pkgs.nodejs}/bin/npx";
            args = [
              "-y"
              "anydb-mcp"
            ];
          };

          # ── DevOps ──────────────────────────────────────────────────────────
          "devops/docker" = {
            command = "${pkgs.nodejs}/bin/npx";
            args = [
              "-y"
              "@alisaitteke/docker-mcp"
            ];
          };

          "devops/kubernetes" = {
            command = "${pkgs.nodejs}/bin/npx";
            args = [
              "-y"
              "kubernetes-mcp-server@latest"
              "--read-only"
            ];
          };
        };
      };
    }
  ];
}
