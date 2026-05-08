{...}: {
  imports = [
    ./settings.nix
    ./mcp.nix
    ./extensions.nix
  ];

  userapps.development.editors.vscode = {
    vendor = "cursor";
  };
}
