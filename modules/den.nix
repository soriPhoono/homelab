{ inputs, ... }:
{
  # Tracks den's `latest` release ref rather than main, so updates are stable
  # releases only. flake.lock holds the exact rev; bump with `nix flake update den`
  # after reading the release notes at https://den.denful.dev/releases/
  flake-file.inputs.den.url = "github:denful/den/latest";

  imports = [ (inputs.den.flakeModule or { }) ];
}
