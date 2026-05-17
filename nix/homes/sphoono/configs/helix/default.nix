{pkgs, ...}: {
  userapps.development.editors.helix = {
    enable = true;
    defaultEditor = true;

    extraPackages = with pkgs; [
      # Language servers
      nixd
      nil
      bash-language-server
      lua-language-server
      marksman
      taplo
      yaml-language-server
      vscode-langservers-extracted
      sqls
      rust-analyzer
      gopls
      zls
      pyright
      typescript-language-server
      biome
      dockerfile-language-server-nodejs
      cmake-language-server
      phpactor
      solargraph
      haskell-language-server
      kotlin-language-server
      dart
      vue-language-server
      svelte-language-server
      graphql-language-service-cli
      helm-ls

      # Formatters / Linters
      ruff
      prettier
      stylelint
    ];

    settings = {
      editor = {
        line-number = "relative";
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
        indent-guides.render = true;
        soft-wrap.enable = true;
      };
    };

    languages = {
      language-server = {
        nixd = {
          command = "${pkgs.nixd}/bin/nixd";
        };
        rust-analyzer = {
          command = "${pkgs.rust-analyzer}/bin/rust-analyzer";
        };
        pyright = {
          command = "${pkgs.pyright}/bin/pyright-langserver";
          args = ["--stdio"];
        };
      };

      language = [
        {
          name = "nix";
          auto-format = true;
          language-servers = ["nixd"];
        }
        {
          name = "rust";
          auto-format = true;
          language-servers = ["rust-analyzer"];
        }
        {
          name = "python";
          language-servers = ["pyright"];
          formatter = {
            command = "${pkgs.ruff}/bin/ruff";
            args = ["format" "-"];
          };
        }
        {
          name = "javascript";
          language-servers = ["typescript-language-server"];
          formatter = {
            command = "${pkgs.prettier}/bin/prettier";
            args = ["--parser" "babel"];
          };
        }
        {
          name = "typescript";
          language-servers = ["typescript-language-server"];
          formatter = {
            command = "${pkgs.prettier}/bin/prettier";
            args = ["--parser" "typescript"];
          };
        }
        {
          name = "go";
          auto-format = true;
          language-servers = ["gopls"];
        }
        {
          name = "zig";
          language-servers = ["zls"];
        }
      ];
    };
  };
}
