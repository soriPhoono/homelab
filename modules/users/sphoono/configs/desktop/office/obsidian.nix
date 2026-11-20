{ den, lib, ... }: {
  den.aspects.sphoono.desktop = {
    includes = [ (den.batteries.unfree [ "obsidian" ]) ];
    homeManager = { pkgs, ... }: {
      programs.obsidian = {
        enable = true;
        cli.enable = true;
        package =
          let
            editor = pkgs.obsidian;
          in
          lib.mkForce (
            pkgs.symlinkJoin {
              pname = editor.pname or "obsidian";
              version = editor.version or "latest";
              name = "${editor.name}-with-python";

              paths = [ editor ];
              buildInputs = [ pkgs.makeWrapper ];
              postBuild = ''
                for bin in $out/bin/*; do
                  if [ -f "$bin" ] && [ -x "$bin" ]; then
                    wrapProgram "$bin" \
                      --prefix PATH : ${lib.makeBinPath [ pkgs.python3 ]}
                  fi
                done
              '';
            }
          );
      };
    };
  };
}
