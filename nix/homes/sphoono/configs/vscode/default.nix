{
  pkgs,
  lib,
  ...
}: {
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
    };

    extensions = with pkgs.vscode-extensions; [
      jnoortheen.nix-ide
    ];

    userSettings = {
      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "${lib.getExe pkgs.nixd}";
      "nix.formatterPath" = "${lib.getExe pkgs.alejandra}";
      "[nix]" = {
        "editor.defaultFormatter" = "jnoortheen.nix-ide";
        "editor.formatOnSave" = true;
      };
    };
  };
}
