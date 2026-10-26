{ pkgs, ... }:
let
  key = lhs: desc: action: {
    key = "<leader>r${lhs}";
    mode = "n";
    inherit desc action;
  };
in
{
  programs.nvf.settings.vim = {
    lazy.plugins."overseer.nvim" = {
      package = pkgs.vimPlugins.overseer-nvim;
      setupModule = "overseer";
      setupOpts = { };
      cmd = [
        "OverseerRun"
        "OverseerToggle"
        "OverseerTaskAction"
        "OverseerQuickAction"
      ];
      keys = [
        (key "r" "Run task" "<cmd>OverseerRun<CR>")
        (key "t" "Toggle task list" "<cmd>OverseerToggle<CR>")
        (key "a" "Task action" "<cmd>OverseerTaskAction<CR>")
        (key "q" "Quick action" "<cmd>OverseerQuickAction<CR>")
      ];
      # Built-in templates cover cargo, make, just, npm and tasks.json; CMake is not among them.
      after = ''
        local overseer = require("overseer")
        local function cmake(name, args)
          overseer.register_template({
            name = "cmake " .. name,
            builder = function()
              return { cmd = { "cmake" }, args = args, components = { "default" } }
            end,
            condition = {
              callback = function(search)
                return vim.fn.filereadable(search.dir .. "/CMakeLists.txt") == 1
              end,
            },
          })
        end
        cmake("configure", { "-S", ".", "-B", "build" })
        cmake("build", { "--build", "build" })
        cmake("test", { "--build", "build", "--target", "test" })
      '';
    };

    binds.whichKey.register."<leader>r" = "+Run";
  };
}
