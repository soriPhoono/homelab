{lib, ...}:
with lib; {
  config = mkMerge [
    {
      userapps.development.agents.opencode = {
        mcpServers = {
        };
      };
    }
  ];
}
