{pkgs, ...}: {
  imports = [
    ./settings.nix
    ./mcp.nix
    ./extensions.nix
  ];

  userapps.development.editors.vscode = {
    package = pkgs.code-cursor;
  };
}
