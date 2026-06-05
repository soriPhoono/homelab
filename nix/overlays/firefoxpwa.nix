_: _final: prev: {
  firefoxpwa = prev.firefoxpwa.overrideAttrs (old: {
    buildCommand =
      builtins.replaceStrings
      [''touch "$out/lib/firefoxpwa/is-packaged-app"'']
      [''mkdir -p "$out/lib/firefoxpwa" && touch "$out/lib/firefoxpwa/is-packaged-app"'']
      old.buildCommand;
  });
}
