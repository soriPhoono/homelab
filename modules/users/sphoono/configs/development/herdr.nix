{ inputs, ... }:
{
  den.aspects.sphoono.development = {
    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        herdrNvim = import ./_private/herdr-nvim.nix { inherit inputs pkgs; };
        tomlFormat = pkgs.formats.toml { };
      in
      {
        imports = [ ./_private/herdr-stylix.nix ];

        programs.herdr = {
          enable = true;
          settings.ui = {
            sidebar_width = 34;
            sidebar_min_width = 24;
            sidebar_max_width = 40;
            agent_panel_sort = "spaces";
            status_indicators = "symbols";
          };
          settings.keys.command = [
            {
              key = "prefix+shift+e";
              type = "plugin_action";
              command = "chmarax.herdr-nvim.toggle";
              description = "nvim sidebar";
            }
            {
              key = "prefix+shift+o";
              type = "plugin_action";
              command = "chmarax.herdr-nvim.pick-file";
              description = "open file from agent output";
            }
          ];
        };

        programs.nvf.settings.vim = {
          extraPlugins.herdr-nvim = {
            package = herdrNvim.vimPlugin;
            # The sidebar daemon calls setup() again on VimEnter; with the
            # plugin's own maps enabled that second call warns once per key.
            # keymaps = false persists in module state, so bind them here.
            setup = "require('herdr-nvim').setup({ keymaps = false })";
          };
          binds.whichKey.register."<leader>a" = "+Agent";
          keymaps = [
            {
              mode = "n";
              key = "<leader>ac";
              action = "<cmd>Herdr comment<CR>";
              desc = "Comment line";
            }
            {
              # `:` rather than <cmd> so the selection reaches the command.
              mode = "x";
              key = "<leader>ac";
              action = ":Herdr comment<CR>";
              desc = "Comment selection";
            }
            {
              mode = "n";
              key = "<leader>al";
              action = "<cmd>Herdr list<CR>";
              desc = "List comments";
            }
            {
              mode = "n";
              key = "<leader>as";
              action = "<cmd>Herdr send<CR>";
              desc = "Paste comments to agent";
            }
            {
              mode = "n";
              key = "<leader>aS";
              action = "<cmd>Herdr submit<CR>";
              desc = "Send comments to agent";
            }
            {
              mode = "n";
              key = "<leader>ai";
              action = "<cmd>Herdr ref<CR>";
              desc = "Reference line at agent cursor";
            }
            {
              mode = "x";
              key = "<leader>ai";
              action = ":Herdr ref<CR>";
              desc = "Reference selection at agent cursor";
            }
          ];
        };

        # The sidebar daemon spawns a headless nvim; point it at the nvf build
        # so it loads this configuration rather than whatever is on PATH.
        xdg.configFile."herdr-nvim/config.toml".source = tomlFormat.generate "herdr-nvim-config.toml" {
          sidebar.nvim_bin = lib.getExe config.programs.nvf.finalPackage;
        };

        # `plugin link` is offline and idempotent; it re-points the registry
        # entry at the new store path on every generation switch.
        home.activation.herdrNvimPlugin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run ${lib.getExe config.programs.herdr.package} plugin link ${herdrNvim.herdrPlugin}/plugin \
            || warnEcho "herdr plugin link failed; run it manually"
        '';
      };
  };
}
