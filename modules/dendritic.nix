{ inputs, lib, ... }:
{
  imports = [
    (inputs.flake-file.lib.flakeModules.flake-parts-builder ../flake-parts)
    inputs.flake-file.flakeModules.auto-follow
    inputs.flake-file.flakeModules.dendritic
  ];

  # flake-parts-builder writes the camelCase keys below from each part's
  # `_meta`, but flake-file's freeform `nixConfig` doesn't merge lists, so
  # parts with differing values conflict. Declare them as mergeable lists.
  options.flake-file.nixConfig = lib.mkOption {
    type = lib.types.submodule {
      options = {
        extraSubstituters = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
        extraTrustedPublicKeys = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
      };
    };
  };
}
