{
  # Krita, with the KritaPilot plugin for agent control. The plugin is linked
  # into Krita's pykrita directory; enable it once under Settings > Configure
  # Krita > Python Plugin Manager ("KritaPilot"), which Krita saves in its
  # own mutable kritarc. It opens a token-guarded bridge on 127.0.0.1:5679.
  den.aspects.spookyskelly.content-creation.krita.homeManager =
    { lib, pkgs, ... }:
    let
      kritapilot = pkgs.callPackage ./_private/packages/kritapilot.nix { };
      plugin = "${kritapilot}/${kritapilot.pluginPath}";
    in
    {
      home.packages = [ pkgs.krita ];

      xdg.dataFile = {
        "krita/pykrita/kritapilot_plugin".source = "${plugin}/kritapilot_plugin";
        "krita/pykrita/kritapilot_plugin.desktop".source = "${plugin}/kritapilot_plugin.desktop";
      };

      programs.mcp.servers.krita.command = lib.getExe kritapilot;
    };
}
