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

  # Devicetree support for ZMK / Zephyr
  devicetree = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    mktplcRef = {
      publisher = "trond-snekvik";
      name = "devicetree";
      version = "2.3.1";
      sha256 = "sha256-xzKxRO3Iz2VzNMMFcX3gdK6VcKdP7JbGp2rhlWme4Xs=";
    };
  };

  # Kconfig language support for ZMK / Zephyr
  kconfig = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    mktplcRef = {
      publisher = "trond-snekvik";
      name = "kconfig-lang";
      version = "1.2.0";
      sha256 = "sha256-uX8CJh7EuwNwmXc3GX2MXPQ9/Xm2PElVD7o8SY0FUqA=";
    };
  };

  # ZMK Tools
  zmk-tools = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    mktplcRef = {
      publisher = "spadin";
      name = "zmk-tools";
      version = "1.5.0";
      sha256 = "sha256-ov2vQXXc4WhAY8NWFzIkMJMeeGutahggpyuJztGXDIs=";
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
        pkgs.vscode-marketplace.formulahendry.acp-client

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

      # ── Systems profile — C/C++, Rust, Zig, ZMK/QMK firmware ────────────────
      systems = {
        extensions = with pkgs.vscode-extensions; [
          # C / C++
          llvm-vs-code-extensions.vscode-clangd
          vadimcn.vscode-lldb

          # Zig
          ziglang.vscode-zig

          # Rust
          rust-lang.rust-analyzer
          serayuzgur.crates

          # Firmware & Build tooling (ZMK / QMK)
          ms-vscode.cmake-tools
          ms-vscode.hexeditor
          devicetree
          kconfig
          zmk-tools
        ];

        userSettings = {
          # C / C++ formatting and flags
          "[c]".editor.defaultFormatter = "llvm-vs-code-extensions.vscode-clangd";
          "[cpp]".editor.defaultFormatter = "llvm-vs-code-extensions.vscode-clangd";
          "clangd.fallbackFlags" = ["-std=c++20"];

          # Rust
          "[rust]".editor.defaultFormatter = "rust-lang.rust-analyzer";
          "rust-analyzer.check.command" = "clippy";
          "rust-analyzer.inlayHints.enable" = true;

          # Zig
          "[zig]".editor.defaultFormatter = "ziglang.vscode-zig";
          "zig.zigPath" = "zig";

          # Firmware (Devicetree / Kconfig)
          "[devicetree]".editor.defaultFormatter = "trond-snekvik.devicetree";
        };
      };
    };
  };
}
