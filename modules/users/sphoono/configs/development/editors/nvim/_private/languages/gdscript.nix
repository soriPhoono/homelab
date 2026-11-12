{ pkgs, ... }:
{
  programs.nvf = {
    # The Godot templates lint and format with gdtoolkit (gdlint, gdformat).
    # The project's copy wins from the direnv shell, this is the fallback.
    settings.mnw.extraBinPath = [ pkgs.gdtoolkit_4 ];

    settings.vim = {
      languages.gdscript = {
        enable = true;
        # Connects to the Godot editor's LSP on 127.0.0.1:6005, so the editor
        # must be running with the project open.
        lsp.servers = [ "gdscript" ];
        # nvf's gdscript-formatter is a different tool than the templates use.
        format.enable = false;
      };
      formatter.conform-nvim = {
        enable = true;
        setupOpts = {
          # gdformat rewrites the file in place, so conform runs it on a copy.
          formatters.gdformat = {
            command = "gdformat";
            args = [ "$FILENAME" ];
            stdin = false;
          };
          formatters_by_ft.gdscript = [ "gdformat" ];
        };
      };
    };
  };
}
