{
  inputs,
  lib,
  pkgs,
}:
{
  programs.opencode.skills = import ../../_private/skills.nix { inherit inputs lib pkgs; };
}
