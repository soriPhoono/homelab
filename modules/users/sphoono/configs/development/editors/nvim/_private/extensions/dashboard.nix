{ lib, ... }:
let
  inherit (lib.generators) mkLuaInline;

  logo = lib.strings.splitString "\n" (builtins.readFile ../../../../../assets/logo.txt);

  button = icon: label: shortcut: command: {
    type = "button";
    val = "${icon}  ${label}";
    on_press = mkLuaInline "function() vim.cmd([[${command}]]) end";
    opts = {
      position = "center";
      inherit shortcut;
      cursor = 5;
      width = 42;
      align_shortcut = "right";
      hl_shortcut = "Keyword";
      keymap = [
        "n"
        shortcut
        "<cmd>${command}<CR>"
        {
          noremap = true;
          silent = true;
          nowait = true;
        }
      ];
    };
  };
in
{
  programs.nvf.settings.vim.dashboard.alpha = {
    enable = true;
    theme = null;
    opts.margin = 5;
    layout = [
      {
        type = "padding";
        val = 2;
      }
      {
        type = "text";
        val = logo;
        opts = {
          position = "center";
          hl = "Type";
        };
      }
      {
        type = "padding";
        val = 2;
      }
      {
        type = "group";
        val = [
          (button "" "Find file" "f" "Telescope find_files")
          (button "" "Find text" "g" "Telescope live_grep")
          (button "" "Recent files" "r" "Telescope oldfiles")
          (button "" "New file" "n" "enew")
          (button "" "File explorer" "e" "Neotree filesystem reveal position=left toggle")
          (button "" "Quit" "q" "qa")
        ];
        opts.spacing = 1;
      }
      {
        type = "padding";
        val = 1;
      }
      {
        type = "text";
        val = [ "sphoono" ];
        opts = {
          position = "center";
          hl = "Comment";
        };
      }
    ];
  };
}
