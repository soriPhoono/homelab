# --- flake-parts/systems.nix
{ inputs, lib, ... }:
{
  # NOTE We use the default `systems` defined by the `nix-systems` flake, minus
  # x86_64-darwin, which nixpkgs 26.11+ no longer supports. If you need any
  # additional systems, simply add them in the following manner
  #
  # `systems = (import inputs.systems) ++ [ "armv7l-linux" ];`
  systems = lib.filter (system: system != "x86_64-darwin") (import inputs.systems);
}
