_: {
  vim = {
    lsp = {
      enable = true;
      formatOnSave = true;
      inlayHints.enable = true;
    };

    languages = {
      enableFormat = true;
      enableTreesitter = true;
      enableExtraDiagnostics = true;

      nix = {
        enable = true;
        format.type = ["alejandra"];
        lsp.servers = ["nixd" "nil"];
        extraDiagnostics.types = ["statix" "deadnix"];
      };

      python = {
        enable = true;
        format.type = ["black" "isort"];
      };
    };
  };
}
