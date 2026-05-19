{pkgs, ...}: {
  userapps.development.agentics.editors.mcp = {
    # Assistant / General (via uvx, original serena-agent PyPI package)
    serena = {
      transport = "stdio";
      command = "${pkgs.uv}/bin/uvx";
      args = [
        "--from"
        "serena-agent"
        "serena"
        "start-mcp-server"
      ];
    };
  };
}
