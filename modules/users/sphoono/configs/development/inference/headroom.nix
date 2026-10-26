/**
  Headroom, the prompt compressor behind 9router's Token Saver. 9router POSTs
  messages to `<url>/v1/compress` before routing them; with Headroom down it
  skips the step. Not in nixpkgs, so uvx runs the pinned PyPI release, as the
  alpaca MCP does. The first start downloads the dependencies (torch for the
  `ml` extra is several GB) and the Kompress model; later starts use caches.

  Enable it in the 9router dashboard (Token Saver) with URL
  http://localhost:8787.
*/
_: {
  den.aspects.sphoono.development.headroom = {
    homeManager =
      {
        lib,
        pkgs,
        ...
      }:
      let
        version = "0.41.0";
        extras = "proxy,code,ml";
      in
      {
        systemd.user.services.headroom = {
          Unit.Description = "Headroom prompt compression proxy";
          Service = {
            # Loopback is also the default; stated because the proxy has no auth.
            ExecStart = lib.concatStringsSep " " [
              (lib.getExe' pkgs.uv "uvx")
              "--python ${lib.getExe pkgs.python313}"
              "--from \"headroom-ai[${extras}]==${version}\""
              "headroom proxy --host 127.0.0.1 --port 8787"
            ];
            Environment = [
              # uv must use the nixpkgs interpreter; downloaded ones do not run.
              "UV_PYTHON_DOWNLOADS=never"
              # The wheels' native libraries (torch, onnxruntime) need libstdc++.
              "LD_LIBRARY_PATH=${
                lib.makeLibraryPath [
                  pkgs.stdenv.cc.cc.lib
                  pkgs.zlib
                ]
              }"
              "HEADROOM_TELEMETRY=off"
              "HEADROOM_UPDATE_CHECK=off"
            ];
            Restart = "on-failure";
            RestartSec = 10;
          };
          Install.WantedBy = [ "default.target" ];
        };

        # Wanted by 9router, not ordered before it: the compression step is
        # skipped while Headroom is still loading its models.
        systemd.user.services."9router".Unit.Wants = [ "headroom.service" ];
      };
  };
}
