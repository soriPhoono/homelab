{
  pkgs,
  config,
  ...
}: {
  apps.development.agents.hermes.profiles.video-editor = {
    providers = {
      memory = {
        honcho.workspace = "content-creation";
      };
    };

    documents = {
      soul = ../assets/documents/video-editor/soul.md;
      user = ../../../sphoono/configs/assets/documents/user.md;
    };

    permissions = {
      accessDirectories = [
        "${config.home.homeDirectory}/Videos"
      ];
    };

    skills = {
      remotion-best-practices = pkgs.skills.remotion-dev.skills.remotion-best-practices;
      remotion-create = pkgs.skills.remotion-dev.skills.remotion-create;
      remotion-markup = pkgs.skills.remotion-dev.skills.remotion-markup;
      remotion-render = pkgs.skills.remotion-dev.skills.remotion-render;
      remotion-studio = pkgs.skills.remotion-dev.skills.remotion-studio;
      remotion-captions = pkgs.skills.remotion-dev.skills.remotion-captions;
      remotion-maps = pkgs.skills.remotion-dev.skills.remotion-maps;
      remotion-interactivity = pkgs.skills.remotion-dev.skills.remotion-interactivity;
      remotion-multimedia = pkgs.skills.remotion-dev.skills.remotion-multimedia;
      remotion-saas = pkgs.skills.remotion-dev.skills.remotion-saas;
      remotion-docs = pkgs.skills.remotion-dev.skills.remotion-docs;
      remotion-upgrade = pkgs.skills.remotion-dev.skills.remotion-upgrade;
    };

    mcpServers = {
      "music/starsinger" = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [
          "-y"
          "starsinger-mcp"
        ];
        env = {
          STARSINGER_API_KEY = {
            secret = "api/STARSINGER_API_KEY";
          };
        };
      };
    };
  };
}
