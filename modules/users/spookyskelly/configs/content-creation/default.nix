{ den, ... }:
{
  den.aspects.spookyskelly.content-creation = {
    includes = [
      den.aspects.spookyskelly.content-creation.audacity
      den.aspects.spookyskelly.content-creation.blender
      den.aspects.spookyskelly.content-creation.krita
      den.aspects.spookyskelly.content-creation.obs-studio
      den.aspects.spookyskelly.content-creation.warudo
    ];

    # The concept-art-to-VTuber pipeline across Krita, VRoid Studio, Blender,
    # Warudo and OBS, each driven through the MCP servers declared above.
    homeManager.programs.antigravity-cli.skills.concept-to-vtuber = ./assets/skills/concept-to-vtuber;
  };
}
