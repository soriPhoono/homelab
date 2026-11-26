{
  # Blender, with the MCP for Blender addon for agent control and the VRM
  # addon for exporting avatars to Warudo. Both are linked into Blender's
  # user addons directory; enable them once under Edit > Preferences >
  # Add-ons ("MCP for Blender", "VRM format"), which Blender saves in its
  # own mutable userpref.blend.
  den.aspects.spookyskelly.content-creation.blender.homeManager =
    { lib, pkgs, ... }:
    let
      mcp-for-blender = pkgs.callPackage ./_private/packages/mcp-for-blender.nix { };
      vrm-addon = pkgs.callPackage ./_private/packages/vrm-addon-for-blender.nix { };
      addonsDir = "blender/${lib.versions.majorMinor pkgs.blender.version}/scripts/addons";
    in
    {
      home.packages = [ pkgs.blender ];

      xdg.configFile = {
        # The file name `uvx mcp-for-blender install-addon` would write, so
        # the server's startup check recognises this copy.
        "${addonsDir}/blender_mcp.py".source = "${mcp-for-blender}/${mcp-for-blender.addonPath}";
        "${addonsDir}/${vrm-addon.moduleName}".source = vrm-addon;
      };

      # The addon listens on localhost:9876 once its server is started from
      # the MCP for Blender tab in the N sidebar.
      programs.mcp.servers.blender = {
        command = lib.getExe mcp-for-blender;
        env.DISABLE_TELEMETRY = "true";
      };
    };
}
