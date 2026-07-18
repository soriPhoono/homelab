{pkgs, ...}: let
  # Nix IDE v0.5.5 — pinned to a version compatible with Antigravity IDE's
  # bundled VS Code engine (v1.107.0).  The nixpkgs version (v0.5.9) requires
  # VS Code >= 1.112.0, which postdates the engine shipped inside Antigravity.
  nix-ide = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    mktplcRef = {
      publisher = "jnoortheen";
      name = "nix-ide";
      version = "0.5.5";
      sha256 = "sha256-epdEMPAkSo0IXsd+ozicI8bjPPquDKIzB3ONRUYWwn8=";
    };
  };

  # Kubernetes Tools v1.3.0 — pinned to a version compatible with Antigravity
  # IDE's bundled VS Code engine (v1.107.0).  The nixpkgs version (v1.4.0)
  # requires VS Code >= 1.110.0, which postdates the engine shipped inside
  # Antigravity.
  k8s-tools = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    mktplcRef = {
      publisher = "ms-kubernetes-tools";
      name = "vscode-kubernetes-tools";
      version = "1.3.0";
      sha256 = "sha256-mXM9mA6oJ/qQgS/NgctpkvUNfouMBD30ayLs25H3sH0=";
    };
  };
in {
  apps.development.editors.antigravity = {
    # Common extensions added to EVERY profile — keep this minimal.
    # Language-specific tools belong in profile extensions instead.
    common = {
      extensions = with pkgs.vscode-extensions; [
        pkgs.vscode-marketplace.ms-vscode.atom-keybindings
        catppuccin.catppuccin-vsc

        # Nix Code
        mkhl.direnv
        # Pinned to v0.5.5 — newer versions require VS Code >= 1.112 which
        # Antigravity IDE's bundled engine (v1.107.0) doesn't meet.
        nix-ide

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
        tamasfe.even-better-toml

        # Tooling
        christian-kohler.path-intellisense

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
        extensions = with pkgs.vscode-extensions; [
          # Golang
          golang.go

          # Python
          ms-python.python
          ms-python.vscode-pylance

          # Container ops
          ms-azuretools.vscode-containers
          # Pinned to v1.3.0 — newer versions require VS Code >= 1.110 which
          # Antigravity IDE's bundled engine (v1.107.0) doesn't meet.
          k8s-tools

          # Terraform / OpenTofu
          hashicorp.hcl

          # GitLab
          gitlab.gitlab-workflow

          # Grafana
          pkgs.vscode-marketplace.grafana.grafana-vscode
        ];

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
          pkgs.vscode-marketplace.sorbet.sorbet-vscode-extension

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
