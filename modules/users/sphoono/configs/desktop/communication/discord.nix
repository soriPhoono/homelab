{ den, ... }:
{
  den.aspects.sphoono.desktop = {
    includes = [
      (den.batteries.unfree [
        "discord"
        "discord-unwrapped"
      ])
    ];
    homeManager = {
      programs.discord.enable = true;
    };
  };
}
