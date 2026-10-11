{ inputs, ... }: {
  flake-file.inputs.artcraft.url = "github:devitek/artcraft-nixos";
  den.aspects.sphoono.desktop = {
    homeManager = {
      imports = [
        inputs.artcraft.homeManagerModules.default
      ];
      programs.artcraft = {
        enable = true;
        apps = [
          "photocraft"
          "vectorcraft"
          "filmcraft"
          "lightcraft"
          "pdfcraft"
          "effectcraft"
          "designcraft"
          "gridcraft"
          "wordcraft"
          "deckcraft"
          "cadcraft"
          "soundcraft"
        ];
      };
    };
  };
}
