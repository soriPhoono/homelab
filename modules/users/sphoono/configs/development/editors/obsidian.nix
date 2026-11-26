{ den, lib, ... }: {
  den.aspects.sphoono.development.editors.obsidian = {
    includes = [ (den.batteries.unfree [ "obsidian" ]) ];
    homeManager = { pkgs, ... }: {
      wayland.windowManager.hyprland.settings.bind =
        let
          desktop = pkgs.obsidian;
          inherit (import ../../core/wm/hypr/_private/lib.nix { inherit lib; }) bind exec;
        in
        [
          (bind "SUPER + N" (exec "${lib.getExe pkgs.uwsm} app -- ${lib.getExe desktop}"))
        ];

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
