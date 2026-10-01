{ inputs, ... }:
{
  flake-file.inputs.stylix.url = "github:nix-community/stylix";
  den.aspects.stylix = {
    # The NixOS module injects the HM module into every host user itself.
    nixos.imports = [ inputs.stylix.nixosModules.stylix ];
    # Only for homes with no NixOS host; on a host this would define
    # stylix.base16 twice and the scheme is inherited from the NixOS side.
    standalone.homeManager.imports = [ inputs.stylix.homeModules.stylix ];
  };
}
