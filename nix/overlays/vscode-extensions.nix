{inputs, ...}: final: prev: let
  extensions = inputs.nix-vscode-extensions.overlays.default final prev;
in
  extensions
  // {
    vscode-marketplace =
      extensions.vscode-marketplace
      // {
        sumneko =
          extensions.vscode-marketplace.sumneko
          // {
            lua = extensions.vscode-marketplace.sumneko.lua.overrideAttrs (_old: {
              patches = [];
            });
          };

        hashicorp =
          extensions.vscode-marketplace.hashicorp
          // {
            inherit (prev.vscode-extensions.hashicorp) terraform;
          };
      };
    vscode-marketplace-universal =
      extensions.vscode-marketplace-universal
      // {
        sumneko =
          extensions.vscode-marketplace-universal.sumneko
          // {
            lua = extensions.vscode-marketplace-universal.sumneko.lua.overrideAttrs (_old: {
              patches = [];
            });
          };

        hashicorp =
          extensions.vscode-marketplace-universal.hashicorp
          // {
            inherit (prev.vscode-extensions.hashicorp) terraform;
          };
      };
  }
