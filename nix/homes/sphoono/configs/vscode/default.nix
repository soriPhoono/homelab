{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./extensions.nix

    ./settings.nix
  ];

  userapps.development.editors.vscode = {
    package = pkgs.symlinkJoin {
      pname = pkgs.antigravity.pname or "vscode";
      version = pkgs.antigravity.version or "latest";
      name = "${pkgs.antigravity.name or "antigravity"}-wrapped";

      paths = [pkgs.antigravity];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/antigravity \
          --prefix PATH : ${lib.makeBinPath [pkgs.google-chrome]}
      '';

      meta.mainProgram = pkgs.antigravity.meta.mainProgram or "antigravity";
    };
  };
}
