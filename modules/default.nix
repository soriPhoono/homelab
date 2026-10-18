{ inputs, ... }:
{
  flake-file = {
    outputs = "flake-parts";
    inputs = {
      flake-file.url = "github:denful/flake-file";
    };
  };

  imports = [
    (inputs.flake-file.lib.flakeModules.flake-parts-builder ../flake-system)
    (inputs.flake-file.flakeModules.auto-follow or { })
    (inputs.flake-file.flakeModules.dendritic or { })
  ];
}
