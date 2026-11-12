{ inputs, ... }: {
  flake-file.inputs.nvf.url = "github:notashelf/nvf";

  den.aspects.sphoono.development.nvim = {
    homeManager = {
      imports = [
        inputs.nvf.homeModules.default

        ./_private
      ];
      programs.nvf.enable = true;
      programs.nvf.defaultEditor = true;
    };
  };
}
