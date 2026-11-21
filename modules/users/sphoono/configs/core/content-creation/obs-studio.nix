{
  den.aspects.sphoono.core.content-creation.blender.homeManager =
    { pkgs, ... }:
    {
      programs.obs-studio = {
        enable = true;
        plugins = with pkgs.obs-studio-plugins; [
          # Hardware acceleration
          obs-vaapi

          # Capture methods
          obs-pipewire-audio-capture
          obs-vkcapture
          input-overlay

          # Filters
          obs-backgroundremoval
          pixel-art
        ];
      };
    };
}
