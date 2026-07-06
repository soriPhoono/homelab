{pkgs, ...}: let
  # Grafana VS Code extension — not in nixpkgs, fetched from marketplace
  grafana = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    mktplcRef = {
      publisher = "Grafana";
      name = "grafana-vscode";
      version = "0.0.19";
      sha256 = "sha256-TpLOMwdaEdgzWVwUcn+fO4rgLiQammWQM8LQobt8gLw=";
    };
  };

  # Sorbet VS Code extension — not in nixpkgs, fetched from marketplace
  sorbet = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    mktplcRef = {
      publisher = "sorbet";
      name = "sorbet-vscode-extension";
      version = "0.3.46";
      sha256 = "sha256-fKJbaJgsLgypprylbUKUjyeU1B9x0RlaD1dUnFd1w7Y=";
    };
  };
in {
  userapps.development.editors.vscode = {
    # Common extensions added to EVERY profile — keep this minimal.
    # Language-specific tools belong in profile extensions instead.
    common = {
      extensions = with pkgs.vscode-extensions; [
        catppuccin.catppuccin-vsc

        # Nix Code
        mkhl.direnv
        jnoortheen.nix-ide

        # Shell script
        foxundermoon.shell-format
        timonwong.shellcheck

        # Docs
        bierner.markdown-mermaid
        streetsidesoftware.code-spell-checker
        yzhang.markdown-all-in-one

        # Configuration
        redhat.vscode-xml
        redhat.vscode-yaml

        # CI/CD
        github.vscode-github-actions
      ];

      # Common keybindings (merged before profile-specific ones)
      keybindings = [
        # Nix-specific: evaluate current file
        {
          key = "ctrl+shift+n";
          command = "nix-ide.evaluate";
          when = "editorLangId == 'nix'";
        }
      ];

      # Common language snippets
      languageSnippets = {
        nix = {
          "Nix flake check" = {
            prefix = ["flakecheck" "nfc"];
            body = ''nix flake check --all-systems'';
            description = "Full flake validation command";
          };
        };
      };
    };

    # Named extension profiles — switch between them in VS Code via
    # Ctrl+Shift+P → "Profile: Switch" (or click the gear icon bottom-left).
    extensionProfiles = {
      # ── DevOps profile — infra / ops ──────────────────────────────────────
      devops = {
        extensions = with pkgs.vscode-extensions;
          [
            # Golang
            golang.go

            # Python
            ms-python.python
            ms-python.vscode-pylance

            # Container ops
            ms-azuretools.vscode-containers
            ms-kubernetes-tools.vscode-kubernetes-tools

            # Terraform / OpenTofu
            hashicorp.hcl

            # GitLab
            gitlab.gitlab-workflow
          ]
          # Grafana (marketplace-only)
          ++ [grafana];

        userSettings = {
          # Container Tools — Docker client
          "containers.containerClient" = "com.microsoft.visualstudio.containers.docker";
          "containers.orchestratorClient" = "com.microsoft.visualstudio.orchestrators.dockercompose";

          # Kubernetes
          "vs-kubernetes.kubectl-path" = "kubectl";
          "vs-kubernetes.namespace" = "";
          "vs-kubernetes.outputFormat" = "yaml";
          "vs-kubernetes.suppress-kubectl-not-found-alerts" = true;

          # HCL / OpenTofu
          "[terraform]".editor.tabSize = 2;
          "[terraform-vars]".editor.tabSize = 2;
        };
      };

      # ── Fullstack profile — complex web development ──────────────────────
      # Languages: Go, Rust (Rocket), Python (Django), Ruby (Rails),
      #            JavaScript/TypeScript (Svelte, Next.js, Vue)
      fullstack = {
        extensions = with pkgs.vscode-extensions; [
          # Go
          golang.go

          # Rust
          rust-lang.rust-analyzer

          # Python
          ms-python.python
          ms-python.vscode-pylance

          # Ruby — Shopify LSP + Sorbet type checker
          shopify.ruby-lsp
          sorbet

          # JavaScript / TypeScript
          dbaeumer.vscode-eslint

          # Svelte
          svelte.svelte-vscode

          # Vue
          vue.volar
          vue.vscode-typescript-vue-plugin

          # Formatting
          esbenp.prettier-vscode

          # Tooling
          christian-kohler.npm-intellisense
          mikestead.dotenv
          tamasfe.even-better-toml
        ];

        userSettings = {
          # Prettier as default formatter for web languages
          "[javascript]" = {
            "editor.defaultFormatter" = "esbenp.prettier-vscode";
          };
          "[typescript]" = {
            "editor.defaultFormatter" = "esbenp.prettier-vscode";
          };
          "[css]" = {
            "editor.defaultFormatter" = "esbenp.prettier-vscode";
          };
          "[html]" = {
            "editor.defaultFormatter" = "esbenp.prettier-vscode";
          };

          # Rust-analyzer
          "rust-analyzer.check.command" = "clippy";
          "rust-analyzer.inlayHints.enable" = true;

          # ESLint
          "eslint.enable" = true;
          "eslint.format.enable" = true;
          "eslint.run" = "onSave";

          # Python
          "python.languageServer" = "pylance";
        };
      };

      # ── Webdev profile — distilled from fullstack ────────────────────────
      webdev = {
        extensions = with pkgs.vscode-extensions; [
          # JavaScript / TypeScript
          dbaeumer.vscode-eslint

          # Formatting
          esbenp.prettier-vscode

          # Tooling
          christian-kohler.npm-intellisense
          mikestead.dotenv

          # Preview
          ms-vscode.live-server
        ];

        userSettings = {
          # Prettier as default formatter for web languages
          "[javascript]".editor.defaultFormatter = "esbenp.prettier-vscode";
          "[typescript]".editor.defaultFormatter = "esbenp.prettier-vscode";
          "[css]".editor.defaultFormatter = "esbenp.prettier-vscode";
          "[html]".editor.defaultFormatter = "esbenp.prettier-vscode";

          # ESLint
          "eslint.enable" = true;
          "eslint.format.enable" = true;
          "eslint.run" = "onSave";

          # Live preview
          "liveServer.settings.donotShowInfoMsg" = true;
          "liveServer.settings.donotVerifyTags" = true;
        };
      };
    };
  };
}
