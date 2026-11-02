/**
  The Honcho config shared by the agents. Each agent reads its own `hosts.*`
  block from `~/.honcho/config.json` and shares the API key and peer name.
  Workspaces are kept apart: OpenCode works in `software-development`, Codex in
  `personal-assistant`.
*/
_: {
  den.aspects.sphoono.development.honcho = {
    homeManager =
      {
        config,
        lib,
        ...
      }:
      {
        sops = {
          secrets."api/honcho-api-key" = { };
          # Mirrors the file the plugins generate for themselves on first run.
          templates."honcho/config.json".content = builtins.toJSON {
            apiKey = config.sops.placeholder."api/honcho-api-key";
            baseUrl = "https://api.honcho.dev";
            peerName = "sphoono";
            hosts.opencode = {
              workspace = "software-development";
              aiPeer = "opencode";
              removeUserPrefix = true;
              observationMode = "unified";
            };
            hosts.codex = {
              workspace = "personal-assistant";
              aiPeer = "codex";
            };
          };
        };

        # The OpenCode plugin rewrites this file through honcho_set_config, so
        # install a real file instead of linking the read-only template. Each
        # activation resets it to the declared state.
        home.activation.honchoConfig = lib.hm.dag.entryAfter [ "sops-nix" ] ''
          honchoSrc=${config.sops.templates."honcho/config.json".path}
          if [ -r "$honchoSrc" ]; then
            run install -D -m 0600 "$honchoSrc" "$HOME/.honcho/config.json"
          else
            warnEcho "sops template $honchoSrc is unreadable; ~/.honcho/config.json not written"
          fi
          unset honchoSrc
        '';
      };
  };
}
