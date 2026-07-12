{
  imports = [
    ./settings.nix
    ./extensions.nix
  ];

  apps.development.editors.zed.secrets = [
    "api/OPENCODE_API_KEY"
  ];

  xdg.configFile."zed/snippets" = {
    source = ./snippets;
    recursive = true;
  };
}
