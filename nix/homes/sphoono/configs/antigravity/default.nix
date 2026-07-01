{pkgs, ...}: {
  userapps.development.editors.antigravity-ide = {
    enable = true;

    # ── AI / Agent features (all on by default) ──
    enableAgents = true;
    enableAgentCompletions = true;
    enableArtifacts = true;
    enableTerminalAgent = true;
    enableMCP = true;

    # ── Editor config ──
    defaultEditor = false;
    enableAutoUpdate = false;
    enableTelemetry = false;

    extraPackages = with pkgs; [
      # Language servers
      nixd
      nil
      rust-analyzer
      gopls
      pyright
      typescript-language-server
      biome
      alejandra
      ruff
    ];
  };
}
