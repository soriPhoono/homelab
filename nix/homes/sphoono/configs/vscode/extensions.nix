{pkgs, ...}: {
  apps.development.editors.vscode = {
    # Common extensions added to EVERY profile — keep this minimal.
    # Language-specific tools belong in profile extensions instead.
    common = {
      extensions = with pkgs.vscode-marketplace; [
        ms-vscode.atom-keybindings
        catppuccin.catppuccin-vsc
        anthropic.claude-code

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
        tamasfe.even-better-toml

        # Tooling
        ms-vscode-remote.remote-ssh
        christian-kohler.path-intellisense

        # CI/CD
        github.vscode-github-actions
      ];
    };

    # Named extension profiles — switch between them in VS Code via
    # Ctrl+Shift+P → "Profile: Switch" (or click the gear icon bottom-left).
    extensionProfiles = {
      # ── DevOps profile — infra / ops ──────────────────────────────────────
      devops = {
        extensions = with pkgs.vscode-marketplace; [
          # Golang
          golang.go

          # Python
          ms-python.python
          ms-python.vscode-python-envs
          ms-python.vscode-pylance

          # Ansible infra automation
          redhat.ansible

          # Container ops
          ms-azuretools.vscode-containers
          ms-kubernetes-tools.vscode-kubernetes-tools

          # Terraform / OpenTofu
          hashicorp.hcl
          hashicorp.terraform
          gruntwork.terragrunt-ls
          nandovdk.tflint-vscode
          tfsec.tfsec
          derekcashmore.terraform-docs
          saramorillon.terraform-graph

          # GitLab
          gitlab.gitlab-workflow

          # Grafana
          grafana.grafana-vscode
        ];

        userSettings = {
          # Python
          "python.useEnvironmentsExtension" = false;

          # Container Tools — Docker client
          "containers.containerClient" = "com.microsoft.visualstudio.containers.docker";
          "containers.orchestratorClient" = "com.microsoft.visualstudio.orchestrators.dockercompose";

          # Kubernetes
          "vs-kubernetes.kubectl-path" = "kubectl";
          "vs-kubernetes.namespace" = "";
          "vs-kubernetes.outputFormat" = "yaml";
          "vs-kubernetes.suppress-kubectl-not-found-alerts" = true;

          # HCL / OpenTofu / Terraform
          "[terraform]" = {
            "editor.tabSize" = 2;
          };
          "[terraform-vars]" = {
            "editor.tabSize" = 2;
          };
          "[hcl]" = {
            "editor.tabSize" = 2;
          };

          # Prefer OpenTofu while maintaining compatibility with official Terraform registry
          "terraform.languageServer.enable" = true;
          "terraform.languageServer.args" = ["serve"];
          "terraform.indexing.enabled" = true;
          "terraform.validation.enableEnhancedValidation" = true;

          # TFLint & Terragrunt
          "tflint.enable" = true;
          "terragrunt.path" = "terragrunt";
        };
      };

      # ── Fullstack profile — complex web development ──────────────────────
      # Languages: Go, Rust (Rocket), Python (Django), Ruby (Rails),
      #            JavaScript/TypeScript (Svelte, Next.js, Vue)
      fullstack = {
        extensions = with pkgs.vscode-marketplace; [
          # Go
          golang.go

          # Rust
          rust-lang.rust-analyzer

          # Python
          ms-python.python
          ms-python.vscode-pylance

          # Ruby — Shopify LSP + Sorbet type checker
          shopify.ruby-lsp
          sorbet.sorbet-vscode-extension

          # JavaScript / TypeScript
          dbaeumer.vscode-eslint

          # Svelte
          svelte.svelte-vscode

          # Vue
          vue.volar

          # Formatting
          esbenp.prettier-vscode

          # Tooling
          christian-kohler.npm-intellisense
          mikestead.dotenv

          # Shopify platform for e-commerce
          shopify.theme-check-vscode
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

      # ── Systems profile — C/C++, Rust, Zig, ZMK/QMK firmware ────────────────
      systems = {
        extensions = with pkgs.vscode-marketplace; [
          # C / C++
          llvm-vs-code-extensions.vscode-clangd
          pkgs.vscode-extensions.vadimcn.vscode-lldb

          # Zig
          ziglang.vscode-zig

          # Rust
          rust-lang.rust-analyzer
          serayuzgur.crates

          # Firmware & Build tooling (ZMK / QMK)
          ms-vscode.cmake-tools
          ms-vscode.hexeditor
          trond-snekvik.devicetree
          trond-snekvik.kconfig-lang
          spadin.zmk-tools
        ];

        userSettings = {
          # C / C++ formatting and flags
          "[c]" = {
            "editor.defaultFormatter" = "llvm-vs-code-extensions.vscode-clangd";
          };
          "[cpp]" = {
            "editor.defaultFormatter" = "llvm-vs-code-extensions.vscode-clangd";
          };
          "clangd.fallbackFlags" = ["-std=c++20"];

          # Rust
          "[rust]" = {
            "editor.defaultFormatter" = "rust-lang.rust-analyzer";
          };
          "rust-analyzer.check.command" = "clippy";
          "rust-analyzer.inlayHints.enable" = true;

          # Zig
          "[zig]" = {
            "editor.defaultFormatter" = "ziglang.vscode-zig";
          };
          "zig.zigPath" = "zig";

          # Firmware (Devicetree / Kconfig)
          "[devicetree]" = {
            "editor.defaultFormatter" = "trond-snekvik.devicetree";
          };
        };
      };

      data-science = {
        extensions = with pkgs.vscode-marketplace; [
          # Python
          ms-python.python
          ms-python.vscode-pylance

          # Jupyter notebooks
          ms-toolsai.jupyter
          ms-toolsai.jupyter-keymap
          ms-toolsai.jupyter-renderers
        ];

        userSettings = {};
      };
    };
  };
}
