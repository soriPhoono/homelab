{
  imports = [
    ./settings.nix
    ./extensions.nix
  ];

  userapps.development.editors.zed.secrets = [
    "api/OPENROUTER_API_KEY"
  ];
}
