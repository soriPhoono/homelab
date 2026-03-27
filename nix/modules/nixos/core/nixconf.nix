{
  inputs,
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.core.nixconf;
in
  with lib; {
    options.core.nixconf = {
      determinate.enable = mkEnableOption "determinate.nix";
    };

    config = {
      environment.systemPackages = with pkgs; [git];

      determinate = {
        inherit (cfg.determinate) enable;
      };

      nix = let
        flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
      in {
        settings = {
          download-buffer-size = 1073741824;

          # Enable flakes and new 'nix' command
          experimental-features = "nix-command flakes";
          # Opinionated: disable global registry
          flake-registry = "";

          trusted-users = lib.mapAttrsToList (name: _: name) (lib.filterAttrs (_: user: user.admin) config.core.users);

          # Limit the number of cores used per build job to prevent OOM
          # during memory-intensive compilations (like browsers).
          cores = 4;

          # Common substituters applicable to all systems
          substituters =
            [
              "https://cache.nixos.org"
              "https://nix-community.cachix.org"
              "https://numtide.cachix.org"
            ]
            ++ (
              if cfg.determinate.enable
              then ["https://install.determinate.systems"]
              else []
            );
          trusted-public-keys =
            [
              "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
              "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
              "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
            ]
            ++ (
              if cfg.determinate.enable
              then ["cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="]
              else []
            );
        };
        # Opinionated: disable channels
        channel.enable = false;

        # Opinionated: make flake registry and nix path match flake inputs
        registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
        nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
      };
    };
  }
