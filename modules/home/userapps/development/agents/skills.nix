{
  lib,
  config,
  ...
}: let
  # Fetch and discover skills from a git URL
  fetchCollection = url: let
    src = builtins.fetchGit {inherit url;};
    entries = builtins.readDir "${src}/skills";
    skillDirs =
      lib.filterAttrs (
        n: t:
          t == "directory" && builtins.pathExists "${src}/skills/${n}/SKILL.md"
      )
      entries;
  in
    lib.mapAttrs (name: _: {
      source = "${src}/skills/${name}";
    })
    skillDirs;

  cfg = config.userapps.development.agents.skills;
in
  with lib; {
    options.userapps.development.agents.skills = {
      enable = mkEnableOption "Enable skills";

      skillRegistries = mkOption {
        type = with types;
          listOf (oneOf [
            (submodule {
              options = {
                url = mkOption {
                  type = str;
                  description = "Git URL to skill collection.";
                  example = "https://github.com/user/core-skills";
                };

                agents = mkOption {
                  type = with types; listOf (enum ["global" "gemini" "claude"]);
                  default = ["global"];
                  description = "List of agents to apply the skill collection to.";
                };
              };
            })
            str
          ]);
        default = [];
        description = "List of git URLs to fetch skills from";
        example = [
          {
            url = "https://github.com/soriphoono/skills";
            agents = ["global"];
          }
        ];
      };
    };

    config = mkIf cfg.enable (let
      # Normalize string entries to { url, agents } form
      registries =
        map (
          entry:
            if builtins.isString entry
            then {
              url = entry;
              agents = ["global"];
            }
            else entry
        )
        cfg.skillRegistries;

      # Collect skills per agent from registries
      skillsForAgent = agent:
        lib.foldl' (
          acc: reg:
            if builtins.elem agent reg.agents
            then acc // fetchCollection reg.url
            else acc
        ) {}
        registries;

      # Build home.file entries for a given agent path prefix
      installSkills = prefix: skills:
        lib.mapAttrs' (name: skill: {
          name = "${prefix}/${name}";
          value.source = skill.source;
        })
        skills;

      globalSkills = skillsForAgent "global";
      geminiSkills = skillsForAgent "gemini";
      claudeSkills = skillsForAgent "claude";

      # If Antigravity is the editor, gemini skills also need to be in ~/.agent/skills/
      geminiCfg = config.userapps.development.agents.gemini;
      antigravitySkills =
        if geminiCfg.enable && geminiCfg.overrideEditor
        then globalSkills // geminiSkills
        else globalSkills;
    in {
      home.file = lib.mkMerge [
        (installSkills ".agent/skills" antigravitySkills)
        (installSkills ".gemini/skills" geminiSkills)
        (installSkills ".claude/skills" claudeSkills)
      ];
    });
  }
