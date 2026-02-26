{
  pkgs,
  lib,
  self,
  ...
}: let
  # Get all defined Home Manager configurations
  homeConfigs = self.homeConfigurations or {};

  # Map them to a list of { name = ...; path = ...; } for linkFarm
  entries =
    lib.mapAttrsToList (name: config: {
      name = "home-${name}";
      path = config.activationPackage;
    })
    homeConfigs;

  # Create a sequential chain of derivations to force one-by-one building
  buildSequential = items: let
    chain =
      lib.foldl (acc: item: let
        prev = acc.last or null;
        sequentialPath =
          pkgs.runCommand "seq-${item.name}" {
            prevPath = lib.optionalString (prev != null) prev;
          } ''
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
    pkgs.runCommand "home-builds-skip" {} ''
      echo "No Home Manager configurations found. Skipping."
      touch $out
    ''
  else pkgs.linkFarm "home-builds" sequentialEntries
