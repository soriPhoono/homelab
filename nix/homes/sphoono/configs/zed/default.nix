{
  imports = [
    ./settings.nix
    ./extensions.nix
  ];

  userapps.development.editors.zed.secrets = [
    "api/OPENCODE_API_KEY"
  ];
}
