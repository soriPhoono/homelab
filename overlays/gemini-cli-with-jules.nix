_: final: prev: {
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
}
