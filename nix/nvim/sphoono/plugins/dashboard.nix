{lib, ...}: let
  inherit (lib.generators) mkLuaInline;

  logo =
    lib.splitString "\n"
    (lib.removeSuffix "\n" (builtins.readFile ../../../homes/sphoono/configs/assets/logo.txt));

  button = key: label: command: {
    type = "button";
    val = label;
    on_press = mkLuaInline "function() vim.cmd([[${command}]]) end";
    opts = {
      position = "center";
      shortcut = key;
      cursor = 3;
      width = 50;
      align_shortcut = "right";
      hl_shortcut = "Keyword";
      keymap = [
        "n"
        key
        "<cmd>${command}<CR>"
        {
          noremap = true;
          silent = true;
          nowait = true;
        }
      ];
    };
  };
in {
  vim = {
    dashboard.alpha = {
      enable = true;
      theme = null;
      layout = [
        {
          type = "padding";
          val = 3;
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
            (button "n" "  New file" "enew")
            (button "f" "󰈞  Search files" "Telescope find_files")
            (button "g" "󰈬  Find text" "Telescope live_grep")
            (button "r" "  Recent files" "Telescope oldfiles")
            (button "s" "  Load session" "SessionManager load_session")
            (button "l" "󰒲  Load last session" "SessionManager load_last_session")
            (button "q" "  Quit" "qa")
          ];
          opts = {
            spacing = 1;
          };
        }
      ];
      opts = {
        margin = 5;
      };
    };

    session.nvim-session-manager = {
      enable = true;
      usePicker = true;
      setupOpts = {
        # Keep the dashboard as the no-argument landing page.
        autoload_mode = "Disabled";
        autosave_last_session = true;
      };
    };

    # Load Neo-tree at startup only when a path was supplied.
    lazy.plugins.neo-tree-nvim = {
      event = ["VimEnter"];
      after = ''
        vim.schedule(function()
          local args = vim.fn.argv()
          if #args == 0 then
            return
          end

          if #args == 1 and vim.fn.isdirectory(args[1]) == 1 then
            vim.cmd("silent! Neotree close")
            vim.cmd("Neotree position=float dir=" .. vim.fn.fnameescape(args[1]))
          else
            vim.cmd("Neotree position=left reveal")
          end
        end)
      '';
    };
  };
}
