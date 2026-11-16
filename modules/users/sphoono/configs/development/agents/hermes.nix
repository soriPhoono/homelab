{ den, inputs, ... }: {
  flake-file.inputs = {
    hermes-agent.url = "github:NousResearch/hermes-agent";
    nix-skills.url = "github:sudosubin/nix-skills";
    # Hermes patches patchelf 0.19.2, but nixpkgs master still ships 0.15.2, so
    # the patch fails to apply. Follow the nixpkgs rev hermes was locked against
    # (patchelf 0.19.2) until nixpkgs catches up or hermes drops the patch.
    hermes-nixpkgs.url = "github:NixOS/nixpkgs/02c087f3fe673c9e317f206a627cb6b910336dbe";
    hermes-agent.inputs.nixpkgs.follows = "hermes-nixpkgs";
  };

  den.aspects.sphoono.development.hermes = {
    includes = [
      den.aspects.sphoono.development.honcho
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
          inputs.hermes-agent.homeManagerModules.default
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

            Bind address, port and session token are upstream options under
            `services.hermes-agent.backend`. A non-loopback `host` needs
            credentials, and the units need linger to outlive the login.
          '';
        };

        config = lib.mkMerge [
          {
            programs.hermes-agent = {
              enable = true;
              desktop.enable = true;
            };
          }
          (lib.mkIf (cfg.mode != "desktop") {
            services.hermes-agent = {
              enable = true;
              backend.mode = if cfg.mode == "server" then "dashboard" else "serve";
            };
          })
        ];
      };
  };
}
