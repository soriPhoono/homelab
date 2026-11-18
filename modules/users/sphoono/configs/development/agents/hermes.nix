{ den, inputs, ... }: {
  flake-file.inputs = {
    hermes-agent.url = "github:NousResearch/hermes-agent";
    nix-skills.url = "github:sudosubin/nix-skills";
    # Hermes patches patchelf 0.19.2, but nixpkgs master still ships 0.15.2, so
    # the patch fails to apply. Follow the nixpkgs rev hermes was locked against
    # (patchelf 0.19.2) until nixpkgs catches up or hermes drops the patch.
    hermes-nixpkgs.url = "github:NixOS/nixpkgs/02c087f3fe673c9e317f206a627cb6b910336dbe";
    hermes-agent.inputs.nixpkgs.follows = "hermes-nixpkgs";
    # Declarative profiles on top of upstream's services.hermes-agent. Follow
    # our hermes-agent so there is a single Hermes pin.
    hermes-agent-nix = {
      url = "github:soriPhoono/hermes-agent-nix";
      inputs.hermes-agent.follows = "hermes-agent";
    };
  };

  den.aspects.sphoono.development.hermes = {
    includes = [
      den.aspects.sphoono.development.honcho
      den.aspects.sphoono.development.ninerouter
    ];
    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        # Hermes has no skills option for its default profile; it reads extra
        # skill directories from settings.skills.external_dirs. Each entry of
        # the farm is one skill directory.
        obsidianSkills = pkgs.linkFarm "hermes-obsidian-skills" (
          lib.mapAttrsToList (name: path: { inherit name path; }) {
            inherit (pkgs.agent-skills.github.obsidianmd.obsidian-skills)
              defuddle
              json-canvas
              knap
              obsidian-bases
              obsidian-cli
              obsidian-headless
              obsidian-markdown
              ;
          }
        );
      in
      {
        imports = [
          # Pulls in upstream's module as well.
          inputs.hermes-agent-nix.homeManagerModules.default
        ];

        options.development.hermes.mode = lib.mkOption {
          type = lib.types.enum [
            "desktop"
          ];
          default = "desktop";
          description = ''
            How Hermes runs on this home.

            - "desktop" installs the CLI and Hermes Desktop. The wrapper
              carries HERMES_HOME, and no service runs.
            - "remote" is "desktop" plus the headless backend
              (`hermes serve`) that Hermes Desktop clients connect to.
            - "server" is "desktop" plus the backend with the browser
              dashboard (`hermes dashboard`).

            The backend address and session token are set through
            `development.hermes.backend`. The units need linger to outlive
            the login.
          '';
        };

        config = lib.mkMerge [
          {
            nixpkgs.overlays = [ inputs.nix-skills.overlays.default ];

            programs.hermes-agent = {
              enable = true;
              desktop.enable = true;
            };

            # Enabling the service module alone runs no unit: it only writes
            # config.yaml and .env at activation. Both are needed in every
            # mode, so the 9router provider reaches the CLI and Desktop too.
            services.hermes-agent = {
              enable = true;
              environmentFiles = [ config.sops.templates."hermes/env".path ];
              # Hermes reads SOUL.md from HERMES_HOME, not the working
              # directory, so it goes through hermesHomeFiles. The soul is
              # composed from the shared documents, like the other agents'
              # context.
              hermesHomeFiles."SOUL.md" = ''
                ${builtins.readFile ../../../assets/documents/identities/general-assistant.md}

                ${builtins.readFile ../../../assets/documents/agent-roles/personal-assistant.md}

                ${builtins.readFile ../../../assets/documents/agents/hermes.md}
              '';
              settings = {
                skills.external_dirs = [ obsidianSkills ];

                # Desktop first-run state, so a fresh HERMES_HOME starts
                # straight into the app instead of the onboarding flow.
                onboarding = {
                  run = false;
                  seen.profile_build_offered = true;
                };
                browser.use_real_profile = true;
                telemetry.shared_metrics = {
                  enabled = false;
                  send = false;
                };

                providers."9router" = {
                  api = config.development.ninerouter.url;
                  key_env = "NINEROUTER_API_KEY";
                  transport = "chat_completions";
                };
              };
            };

            sops = {
              secrets."api/9router-api-key" = { };
              templates."hermes/env".content = ''
                NINEROUTER_API_KEY=${config.sops.placeholder."api/9router-api-key"}
              '';
            };
          }
        ];
      };
  };
}
