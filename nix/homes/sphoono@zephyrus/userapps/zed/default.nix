{
  imports = [
    ./settings.nix
    ./extensions.nix
  ];

  userapps.development.editors.zed = {
    enable = true;
    secrets = [
      "api/OPENROUTER_API_KEY"
      "api/CODESTRAL_API_KEY"
    ];
  };
}
