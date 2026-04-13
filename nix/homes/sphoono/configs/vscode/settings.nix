{pkgs, ...}: {
  userapps.development.editors.vscode = {
    userSettings = {
      "git.confirmSync" = false;

      "redhat.telemetry.enabled" = true;

      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "${pkgs.nixd}/bin/nixd";
      "[nix]" = {
        "editor.defaultFormatter" = "jnoortheen.nix-ide";
        "editor.formatOnSave" = true;
      };
    };
  };
}
