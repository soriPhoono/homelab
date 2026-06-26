{
  lib,
  pkgs,
  ...
}:
with lib; {
  config = mkMerge [
    {
      userapps.development.agents.hermes.skills = {
        create-agentsmd = pkgs.skills.github.awesome-copilot.create-agentsmd;

        stop-slop = pkgs.skills.hardikpandya.stop-slop.stop-slop;

        git-commit = pkgs.skills.github.awesome-copilot.git-commit;
      };
    }
  ];
}
