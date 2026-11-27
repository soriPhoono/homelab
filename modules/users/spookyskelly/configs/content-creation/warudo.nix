{
  # Warudo, the 3D VTubing app, controlled through warudo-mcp-server.
  #
  # Warudo is a Windows program: install it from Steam (app 2079120) and run
  # it through Proton, then subscribe to the "MCP Bridge" plugin on the Steam
  # Workshop (item 3809919307). Neither is declared here; Steam owns both.
  #
  # The MCP server runs natively and reaches Warudo over loopback. It finds
  # Warudo's one-time API tokens in Player.log under
  # $HOME/AppData/LocalLow/HakuyaLabs/Warudo, a Windows path, so HOME is
  # pointed at the Proton prefix's Windows user profile.
  den.aspects.spookyskelly.content-creation.warudo.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      warudo-mcp-server = pkgs.callPackage ./_private/packages/warudo-mcp-server { };
      steamAppId = "2079120";
      protonProfile = "${config.xdg.dataHome}/Steam/steamapps/compatdata/${steamAppId}/pfx/drive_c/users/steamuser";
    in
    {
      programs.mcp.servers.warudo = {
        command = lib.getExe warudo-mcp-server;
        env = {
          HOME = protonProfile;
          # Saved poses would otherwise land in the Proton prefix too.
          WARUDO_MCP_POSES_DIR = "${config.xdg.dataHome}/warudo-mcp/poses";
        };
      };
    };
}
