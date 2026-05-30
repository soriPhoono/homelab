{
  lib,
  pkgs,
  ...
}:
with lib; let
  skillPathSpec = types.mkOptionType {
    name = "skillPathSpec";
    description = "{ src, subpath }";
    check = x: builtins.isAttrs x && x ? src && x ? subpath;
  };
in {
  options.userapps.development.agentics.agents.skills = mkOption {
    type = types.attrsOf (
      types.coercedTo
      skillPathSpec
      (value:
        pkgs.stdenv.mkDerivation {
          name = "skill-${builtins.baseNameOf value.subpath}";
          inherit (value) src;
          phases = ["installPhase"];
          installPhase = ''
            mkdir -p "$out"
            cp -r "$src/${value.subpath}/"* "$out/"
          '';
        })
      types.package
    );
    default = {};
    description = ''
      An attribute set of skill derivations to be injected into agent environments.
      Keys are the names of the skills directories.
      Each value can be either:
      - A derivation (package) containing SKILL.md (existing behaviour)
      - An attrset { src, subpath } where src is a fetched source derivation
        (e.g. from fetchFromGitHub or a flake input) and subpath points to the
        skill directory within it. Path specs are automatically converted to
        derivations.
    '';
    example = {
      find-skills = pkgs.skills.vercel-labs.skills.find-skills;
      my-skill = {
        src = pkgs.fetchFromGitHub {
          owner = "soriPhoono";
          repo = "skills";
          rev = "dc411c5596d5646482348e4ab3bda1761f84d1ce";
          hash = "";
        };
        subpath = "skills/obsidian/session-logger";
      };
    };
  };
}
