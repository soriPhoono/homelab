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
      alejandra
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
        biome = {
          command = "${pkgs.biome}/bin/biome";
          args = ["lsp-proxy"];
        };
      };

      language = [
        {
          name = "nix";
          auto-format = true;
          language-servers = ["nixd"];
          formatter = {
            command = "${pkgs.alejandra}/bin/alejandra";
          };
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
          auto-format = true;
          language-servers = ["biome"];
        }
        {
          name = "typescript";
          auto-format = true;
          language-servers = ["biome"];
        }
        {
          name = "jsx";
          auto-format = true;
          language-servers = ["biome"];
        }
        {
          name = "tsx";
          auto-format = true;
          language-servers = ["biome"];
        }
        {
          name = "css";
          auto-format = true;
          language-servers = ["biome"];
        }
        {
          name = "json";
          auto-format = true;
          language-servers = ["biome"];
        }
        {
          name = "html";
          language-servers = ["vscode-html-language-server"];
          formatter = {
            command = "${pkgs.prettier}/bin/prettier";
            args = ["--parser" "html"];
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
