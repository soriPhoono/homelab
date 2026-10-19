_: {
  # 9router, a local OpenAI-compatible gateway the coding agents point at.
  # It compresses tool output (RTK) and falls back across providers when a
  # subscription quota runs out. Rootless podman container on loopback only;
  # providers and API keys are added imperatively in the dashboard at
  # http://localhost:20128, and persist in the `9router-data` volume.
  den.aspects.sphoono.development."9router" = {
    homeManager =
      { config, ... }:
      {
        services.podman = {
          enable = true;
          containers."9router" = {
            description = "9router AI gateway";
            # Pinned by digest; bump the tag and digest together.
            image = "docker.io/decolua/9router:0.5.104@sha256:5fc7020f3cf1ca6831bffe80314ecab9dde915d27ee3c479a4bb66f45dabbc27";
            ports = [ "127.0.0.1:20128:20128" ];
            # A named volume, not a bind mount: the entrypoint chowns the data
            # directory to the container's `node` user, which a rootless bind
            # mount would hand to a subuid the host user cannot read.
            volumes = [ "9router-data:/app/data" ];
            environment = {
              DATA_DIR = "/app/data";
              # Every /v1 request needs a key generated in the dashboard.
              REQUIRE_API_KEY = true;
              # Loopback over plain http, so the cookie cannot be Secure.
              AUTH_COOKIE_SECURE = false;
              # Request logs hold prompts and code.
              ENABLE_REQUEST_LOGS = false;
            };
            environmentFile = [ config.sops.templates."9router.env".path ];
            # The env file is rendered by sops-nix at login.
            extraConfig.Unit.After = [ "sops-nix.service" ];
          };
        };

        sops = {
          secrets = {
            "api/9router-jwt-secret".mode = "0400";
            "api/9router-initial-password".mode = "0400";
            "api/9router-api-key-secret".mode = "0400";
          };
          # Rendered at activation, so the values never enter the nix store.
          templates."9router.env".content = ''
            JWT_SECRET=${config.sops.placeholder."api/9router-jwt-secret"}
            INITIAL_PASSWORD=${config.sops.placeholder."api/9router-initial-password"}
            API_KEY_SECRET=${config.sops.placeholder."api/9router-api-key-secret"}
          '';
        };
      };
  };
}
