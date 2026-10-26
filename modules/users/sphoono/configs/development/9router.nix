/**
  9router, a local OpenAI-compatible gateway the coding agents point at. It
  falls back across providers when a subscription quota runs out and fronts
  local models such as Ollama. Providers are added imperatively in the
  dashboard at http://localhost:20128 and persist in the user state directory.
*/
_: {
  den.aspects.sphoono.development."9router" = {
    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        systemd.user.services."9router" = {
          Unit = {
            Description = "9router AI gateway";
            # The env file is rendered by sops-nix at login.
            After = [ "sops-nix.service" ];
          };
          Service = {
            # The default host is 0.0.0.0, and no API key is required, so the
            # loopback bind is the only access control.
            ExecStart = "${lib.getExe pkgs._9router} --host 127.0.0.1 --port 20128 --no-browser --skip-update";
            EnvironmentFile = config.sops.templates."9router.env".path;
            Environment = [
              "NODE_ENV=production"
              "NEXT_TELEMETRY_DISABLED=1"
              "DATA_DIR=%S/9router"
              "REQUIRE_API_KEY=false"
              # Loopback over plain http, so the cookie cannot be Secure.
              "AUTH_COOKIE_SECURE=false"
              # Request logs hold prompts and code.
              "ENABLE_REQUEST_LOGS=false"
            ];
            StateDirectory = "9router";
            Restart = "on-failure";
          };
          Install.WantedBy = [ "default.target" ];
        };

        sops = {
          secrets = {
            "api/9router-jwt-secret".mode = "0400";
            "api/9router-initial-password".mode = "0400";
          };
          # Rendered at activation, so the values never enter the nix store.
          templates."9router.env".content = ''
            JWT_SECRET=${config.sops.placeholder."api/9router-jwt-secret"}
            INITIAL_PASSWORD=${config.sops.placeholder."api/9router-initial-password"}
          '';
        };
      };
  };
}
