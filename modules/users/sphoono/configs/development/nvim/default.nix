{ inputs, ... }: {
  flake-file.inputs.nvf.url = "github:notashelf/nvf";

  den.aspects.sphoono.development = {
    homeManager = {
      imports = [
        inputs.nvf.homeManagerModules.default

        ./_private
      ];
      programs.nvf.enable = true;
      programs.nvf.defaultEditor = true;
    };
  };
}
