{
  den.aspects.spookyskelly.content-creation.obs-studio.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      obs-studio-mcp = pkgs.callPackage ./_private/packages/obs-studio-mcp.nix { };
      websocketPort = 4455;
      passwordSecret = "obs/websocket-password";
    in
    {
      programs.obs-studio = {
        enable = true;
        plugins = with pkgs.obs-studio-plugins; [
          # Hardware acceleration
          obs-vaapi

          # Capture methods
          obs-pipewire-audio-capture
          obs-vkcapture
          input-overlay

          # Filters
          obs-backgroundremoval
          pixel-art
        ];
      };

      # obs-websocket listens on every interface, so it always requires the
      # password. The config is rendered from sops; OBS only writes it back
      # when its WebSocket Server Settings dialog is saved, so change the
      # settings here instead.
      sops = {
        secrets.${passwordSecret} = { };
        templates."obs-websocket.json" = {
          path = "${config.xdg.configHome}/obs-studio/plugin_config/obs-websocket/config.json";
          content = builtins.toJSON {
            first_load = false;
            server_enabled = true;
            server_port = websocketPort;
            alerts_enabled = false;
            auth_required = true;
            server_password = config.sops.placeholder.${passwordSecret};
          };
        };
      };

      programs.mcp.servers.obs = {
        command = lib.getExe obs-studio-mcp;
        env = {
          OBS_MCP_HOST = "127.0.0.1";
          OBS_MCP_PORT = toString websocketPort;
          OBS_MCP_PASSWORD.file = config.sops.secrets.${passwordSecret}.path;
        };
      };
    };
}
