# Flake-file wiring and flake.nix builder
{ inputs, lib, ... }:
{
  imports = [
    (inputs.flake-file.lib.flakeModules.flake-parts-builder ../flake-system)
    (inputs.flake-file.flakeModules.auto-follow or { })
    (inputs.flake-file.flakeModules.dendritic or { })
    (inputs.den.flakeModules.dendritic or { })
  ];
  # Tracks den's `latest` release ref rather than main, so updates are stable
  # releases only. flake.lock holds the exact rev; bump with `nix flake update den`
  # after reading the release notes at https://den.denful.dev/releases/
  config.flake-file.inputs.den.url = "github:denful/den/latest";

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
