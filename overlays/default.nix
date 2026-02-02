{lib, ...}: let
  # Get all directories in the current folder
  dirs = lib.filterAttrs (_name: type: type == "directory") (builtins.readDir ./.);
in
  # Import each directory as an overlay
  lib.mapAttrs (name: _: import (./. + "/${name}")) dirs
