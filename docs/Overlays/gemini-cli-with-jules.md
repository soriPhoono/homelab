# Gemini-CLI Overlay

This overlay provides the `gemini-cli-jules` package.

## Purpose

To provide a version of `gemini-cli` that has `jules` available in its `PATH` without exposing `jules` to the global shell environment.

## Implementation

The overlay resides in [overlays/gemini-cli-with-jules.nix](../../overlays/gemini-cli-with-jules.nix).

It uses `symlinkJoin` to combine `gemini-cli` with a `makeWrapper` post-build step:

```nix
gemini-cli-jules = prev.symlinkJoin {
  name = "gemini-cli-jules";
  paths = [prev.gemini-cli];
  nativeBuildInputs = [prev.makeWrapper];
  postBuild = ''
    rm $out/bin/gemini
    makeWrapper ${prev.gemini-cli}/bin/gemini $out/bin/gemini \
      --prefix PATH : ${prev.lib.makeBinPath [final.jules-cli]}
  '';
};
```
