{ inputs, ... }:
{
  flake-file.inputs.stylix.url = "github:nix-community/stylix";
  den.aspects.stylix = {
    # The NixOS module injects the HM module into every host user itself.
    nixos.imports = [ inputs.stylix.nixosModules.stylix ];
    # Only for homes with no NixOS host; on a host this would define
    # stylix.base16 twice and the scheme is inherited from the NixOS side.
    standalone.homeManager =
      { pkgs, ... }:
      {
        imports = [ inputs.stylix.homeModules.stylix ];
        # Mirrors the scheme the hosts set on the NixOS side.
        stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";
      };
  };
}
