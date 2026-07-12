{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.apps.data-fortress.notes.obsidian;
in
  with lib; {
    options.apps.data-fortress.notes.obsidian = {
      enable = mkEnableOption "Enable Obsidian note-taking application";

      package = mkOption {
        type = types.package;
        default = pkgs.obsidian;
        description = "The Obsidian package to use.";
      };
    };

    config = mkIf cfg.enable {
      programs.obsidian = {
        enable = true;
        cli.enable = true;

        package = let
          editor = pkgs.obsidian;
        in
          mkForce (
            pkgs.symlinkJoin {
              pname = editor.pname or "obsidian";
              version = editor.version or "latest";
              name = "${editor.name}-with-secrets";

              paths = [editor];
              buildInputs = [pkgs.makeWrapper];
              postBuild = ''
                for bin in $out/bin/*; do
                  if [ -f "$bin" ] && [ -x "$bin" ]; then
                    wrapProgram "$bin" \
                      --prefix PATH : ${lib.makeBinPath [pkgs.python3]}
                  fi
                done
              '';
            }
          );
      };
    };
  }
