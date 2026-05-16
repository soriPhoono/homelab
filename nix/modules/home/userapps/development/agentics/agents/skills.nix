{
  lib,
  config,
  ...
}: let
  cfg = config.userapps.development.agentics.agents.skills;
in
  with lib; {
    options.userapps.development.agentics.agents.skills = mkOption {
      type = types.attrsOf types.package;
      default = {};
      description = ''
        An attribute set of skill derivations to be injected into agent environments.
        Keys are the names of the skills directories.
        Values are the derivations for the skills.
      '';
      example = literalExpression ''
        {
          find-skills = pkgs.skills.vercel-labs.skills.find-skills;
        }
      '';
    };
  }
