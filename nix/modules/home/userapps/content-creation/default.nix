{
  imports = [
    # Asset creation
    ./blender.nix

    # Content editing
    ./audacity.nix
    ./gimp.nix
    ./kdenlive.nix
    # ./davinci-resolve.nix # TODO: Finish implementing a heavier more feature rich video editor, this is a bit too basic for my needs. Resolve is a bit of a pain to get working on nix, but I think it's worth it.

    # Streaming
    ./obs-studio.nix
  ];
}
