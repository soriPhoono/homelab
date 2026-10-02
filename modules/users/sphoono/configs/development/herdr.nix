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
            setup = "require('herdr-nvim').setup({})";
          };
          binds.whichKey.register."<leader>a" = "+Agent";
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
