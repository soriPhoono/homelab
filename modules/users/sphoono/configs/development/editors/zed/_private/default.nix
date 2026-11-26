{
  imports = [
    ./plugins/nix.nix
  ];

  # External agents come from the ACP registry, not the extension store.
  programs.zed-editor.userSettings.agent_servers = {
    claude-acp.type = "registry";
    opencode.type = "registry";
  };
}
