{ inputs, ... }: {
  flake-file.inputs.nur.url = "github:nix-community/NUR";
  den.aspects.nur = {
    nixos.nixpkgs.overlays = [ inputs.nur.overlays.default ];
    homeManager.nixpkgs.overlays = [ inputs.nur.overlays.default ];
  };
}
