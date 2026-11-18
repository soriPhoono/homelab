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
        ...
      }:
      let
        cfg = config.development.hermes;
      in
      {
        imports = [
          # Pulls in upstream's module as well.
          inputs.hermes-agent-nix.homeManagerModules.default
        ];

        options.development.hermes.mode = lib.mkOption {
          type = lib.types.enum [
            "desktop"
            "remote"
            "server"
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

        # Thin pass-through to services.hermes-agent.backend: null leaves the
        # upstream default. Types and semantics are documented upstream.
        options.development.hermes.backend =
          let
            nullable =
              type:
              lib.mkOption {
                type = lib.types.nullOr type;
                default = null;
              };
          in
          {
            host = nullable lib.types.str // {
              description = ''
                Bind address of the backend. A non-loopback value starts the
                authentication gate and the server rejects any Host header
                that differs from it, so use the name clients connect with,
                for example a Tailscale MagicDNS name.
              '';
            };
            port = nullable lib.types.port;
            waitFor =
              nullable (
                lib.types.enum [
                  "hostname"
                  "interface"
                ]
              )
              // {
                description = ''
                  Poll for the bind target before starting, to win the race
                  against tailscaled at boot. "hostname" waits for `host` to
                  resolve; "interface" binds to the address of `interfaceName`
                  and ignores `host`.
                '';
              };
            interfaceName = nullable lib.types.str;
            sessionTokenFile = nullable lib.types.str // {
              description = ''
                Runtime path to a file holding the raw session token, mode
                0600, for example a sops-nix secret path. Never a Nix path
                literal, which copies the secret into the store. Hermes
                Desktop presents the same token, so it reaches this backend
                instead of starting its own.
              '';
            };
          };

        config = lib.mkMerge [
          {
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
              settings = {
                providers."9router" = {
                  api = config.development.ninerouter.url;
                  key_env = "NINEROUTER_API_KEY";
                  transport = "chat_completions";
                };
                model = {
                  provider = "custom:9router";
                  default = "Primary-models";
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
          (lib.mkIf (cfg.mode != "desktop") {
            services.hermes-agent = {
              backend = {
                mode = if cfg.mode == "server" then "dashboard" else "serve";
              }
              // lib.filterAttrs (_: v: v != null) cfg.backend;
            };
          })
        ];
      };
  };
}
