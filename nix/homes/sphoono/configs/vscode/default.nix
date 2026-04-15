{
  lib,
  pkgs,
  ...
}:
with lib; {
  imports = [
    ./settings.nix
    ./mcp.nix
    ./extensions.nix
  ];

  userapps.development.editors.vscode = {
    package = pkgs.symlinkJoin {
      pname = pkgs.antigravity.pname or "vscode";
      version = pkgs.antigravity.version or "latest";
      name = "${pkgs.antigravity.name or "vscode"}-with-chrome";

      paths = [pkgs.antigravity];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/antigravity \
          --prefix PATH : ${makeBinPath [pkgs.google-chrome]}
      '';

      meta.mainProgram = pkgs.antigravity.meta.mainProgram or "antigravity";
    };
  };
}
