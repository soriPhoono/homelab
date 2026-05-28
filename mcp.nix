{pkgs, ...}: {
  settings.servers = {
    mcp-nixos = {
      command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
    };
  };
  flavors.opencode.enable = true;
}
