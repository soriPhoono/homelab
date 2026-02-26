{
  pkgs,
  lib,
  self,
  ...
}: let
  # Get all defined NixOS configurations
  nixosConfigs = self.nixosConfigurations or {};

  # Map them to a list of { name = ...; path = ...; } for linkFarm
  entries =
    lib.mapAttrsToList (name: config: {
      name = "nixos-${name}";
      path = config.config.system.build.toplevel;
    })
    nixosConfigs;

  # Create a sequential chain of derivations to force one-by-one building
  # This helps avoid OOM by ensuring only one top-level evaluates/builds at a time.
  buildSequential = items: let
    chain =
      lib.foldl (acc: item: let
        prev = acc.last or null;
        # Create a new derivation that depends on the previous one
        sequentialPath =
          pkgs.runCommand "seq-${item.name}" {
            prevPath = lib.optionalString (prev != null) prev;
          } ''
            # This is strictly to force the dependency
            echo "Building ${item.name} after ${
              if prev != null
              then "previous"
              else "nothing"
            }..."
            ln -s ${item.path} $out
          '';
      in {
        last = sequentialPath;
        list =
          acc.list
          ++ [
            {
              inherit (item) name;
              path = sequentialPath;
            }
          ];
      }) {
        last = null;
        list = [];
      }
      items;
  in
    chain.list;

  sequentialEntries = buildSequential entries;
in
  if (entries == [])
  then
    pkgs.runCommand "nixos-builds-skip" {} ''
      echo "No NixOS configurations found. Skipping."
      touch $out
    ''
  else pkgs.linkFarm "nixos-builds" sequentialEntries
