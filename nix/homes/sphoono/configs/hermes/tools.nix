{
  lib,
  pkgs,
  ...
}:
with lib; {
  config = mkMerge [
    {
      # Browser automation packages for Hermes agent.
      # Hermes auto-detects agent-browser on PATH and enables the browser
      # toolset (browser_navigate, browser_snapshot, browser_click, etc.).
      home.packages = with pkgs; [
        # agent-browser CLI — drives local headless Chromium for web page
        # interaction and screenshots.
        agent-browser

        # Chromium — browser engine required by agent-browser.
        chromium
      ];
    }
  ];
}
