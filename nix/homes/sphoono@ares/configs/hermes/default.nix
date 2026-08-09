{
  pkgs,
  config,
  ...
}: {
  apps.development.agents.hermes.profiles.video-editor = {
    providers.memory = {
      honcho.workspace = "content-creation";
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
      hyperframes-cli = pkgs.skills.heygen-com.hyperframes.hyperframes-cli;
      hyperframes = pkgs.skills.heygen-com.hyperframes.hyperframes;
      hyperframes-core = pkgs.skills.heygen-com.hyperframes.hyperframes-core;
      hyperframes-animation = pkgs.skills.heygen-com.hyperframes.hyperframes-animation;
      hyperframes-keyframes = pkgs.skills.heygen-com.hyperframes.hyperframes-keyframes;
      hyperframes-creative = pkgs.skills.heygen-com.hyperframes.hyperframes-creative;
      hyperframes-media-use = pkgs.skills.heygen-com.hyperframes.media-use;
      hyperframes-registry = pkgs.skills.heygen-com.hyperframes.hyperframes-registry;
      hyperframes-figma = pkgs.skills.heygen-com.hyperframes.figma;
      hyperframes-product-launch-video = pkgs.skills.heygen-com.hyperframes.product-launch-video;
      hyperframes-faceless-explainer = pkgs.skills.heygen-com.hyperframes.faceless-explainer;
      hyperframes-pr-to-video = pkgs.skills.heygen-com.hyperframes.pr-to-video;
      hyperframes-embedded-captions = pkgs.skills.heygen-com.hyperframes.embedded-captions;
      hyperframes-talking-head-recut = pkgs.skills.heygen-com.hyperframes.talking-head-recut;
      hyperframes-motion-graphics = pkgs.skills.heygen-com.hyperframes.motion-graphics;
      hyperframes-music-to-video = pkgs.skills.heygen-com.hyperframes.music-to-video;
      hyperframes-slideshow = pkgs.skills.heygen-com.hyperframes.slideshow;
      hyperframes-general-video = pkgs.skills.heygen-com.hyperframes.general-video;
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
