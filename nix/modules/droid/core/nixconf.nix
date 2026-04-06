{
  lib,
  pkgs,
  ...
}:
with lib; {
  environment.packages = with pkgs; [
    git
  ];

  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
      trusted-users = nix-on-droid
      substituters = https://cache.nixos.org https://nix-on-droid.cachix.org https://nix-community.cachix.org https://numtide.cachix.org
      trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-on-droid.cachix.org-1:56snoMJTXmDRC1Ei24CmKoUqvHJ9XCp+nidK7qkMQrU= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE=
    '';
  };
}
