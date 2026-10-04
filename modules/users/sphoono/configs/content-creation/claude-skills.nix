{
  den.aspects.sphoono.content-creation.homeManager =
    { pkgs, ... }:
    {
      # video-segmentation and clip-cutting shell out to ffmpeg; it belongs
      # here rather than on the base desktop/development aspect so it's only
      # present on hosts that opted into this pipeline.
      home.packages = [ pkgs.ffmpeg ];

      # Gated behind this aspect: these skills are useless (and the agent
      # would offer dead advice) on a host that never opted into the
      # content-creation pipeline, so they must not be reachable from
      # sphoono.development alone.
      programs.claude-code.skills = {
        video-segmentation = ../../assets/skills/video-segmentation;
        clip-cutting = ../../assets/skills/clip-cutting;
        stream-pipeline = ../../assets/skills/stream-pipeline;
      };
    };
}
