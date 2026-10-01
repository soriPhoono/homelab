# NOTE: when creating a new profile, be sure to add it to stylix theming

{
  den,
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs.nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
  den.aspects.sphoono.configs.vscode = {
    # vscode itself and some marketplace extensions are unfree. VSCodium
    # would avoid the vscode license, but ms-vscode-remote.remote-ssh
    # deliberately refuses to run on non-Microsoft builds, so this uses
    # real vscode instead.
    includes = [
      (den.batteries.unfree [
        "vscode"
        "vscode-extension-ms-python-vscode-pylance"
        "vscode-extension-ms-vscode-remote-remote-ssh"
      ])
    ];
    homeManager = { pkgs, ... }: {
      nixpkgs.overlays = [ inputs.nix-vscode-extensions.overlays.default ];
      # stylix only themes `profileNames`, which defaults to [ "default" ] -
      # a profile we don't have. List every profile we actually define below.
      stylix.targets.vscode.profileNames = [
        "default"
        "systems"
        "devOps"
        "dataScience"
        "fullstack"
      ];
      programs.vscode = with pkgs.vscode-marketplace; {
        enable = true;
        profiles =
          let
            # vscode-marketplace's "latest" pick for vadimcn.vscode-lldb
            # (1.11.0) fails to build: its codelldb-types crate isn't a
            # workspace member at that tag. vscode-marketplace-release-universal
            # resolves it to 1.12.3, which builds fine at the same
            # nixpkgs/nix-vscode-extensions pins. Other marketplace variants
            # (e.g. switching everything to -release-universal) pick stale
            # versions of other extensions that fail to build for unrelated
            # reasons, so this override is scoped to just vscode-lldb.
            vscodeLldb = pkgs.vscode-marketplace-release-universal.vadimcn.vscode-lldb;
            # vscode-marketplace's "latest" pick for ms-vscode-remote.remote-ssh
            # is a date-coded pre-release build (e.g. 0.129.2026091815), not
            # the stable release (0.128.0) vscode-marketplace-release gives.
            # The pre-release channel is what causes "out of date"/incompatible
            # complaints, despite the higher version number.
            remoteSsh = pkgs.vscode-marketplace-release.ms-vscode-remote.remote-ssh;
            languageExtensions = {
              configurationLanguages = {
                extensions = [
                  redhat.vscode-yaml
                  redhat.vscode-xml
                  tamasfe.even-better-toml
                ];
                userSettings = {
                  "yaml.format.enable" = true;
                  "[yaml]" = {
                    "editor.defaultFormatter" = "redhat.vscode-yaml";
                  };
                };
              };
              nix = {
                extensions = [
                  jnoortheen.nix-ide
                  mkhl.direnv
                ];
                userSettings = {
                  # Nix
                  "[nix]" = {
                    "editor.defaultFormatter" = "jnoortheen.nix-ide";
                  };
                };
              };
              bash = {
                extensions = [
                  foxundermoon.shell-format
                  timonwong.shellcheck
                ];
                userSettings = {
                  # Formatting default formatters
                  "[shellscript]" = {
                    "editor.defaultFormatter" = "foxundermoon.shell-format";
                  };
                };
              };
              cpp = {
                extensions = [
                  ms-vscode.cmake-tools
                  llvm-vs-code-extensions.vscode-clangd
                  vscodeLldb
                ];
                userSettings = {
                  # C/C++
                  "[cpp]" = {
                    "editor.defaultFormatter" = "llvm-vs-code-extensions.vscode-clangd";
                  };
                };
              };
              zig = {
                extensions = [
                  ziglang.vscode-zig
                  vscodeLldb
                ];
                userSettings = {
                  # Zig
                  "zig.zigPath" = "${pkgs.zig}/bin/zig";
                  "[zig]" = {
                    "editor.defaultFormatter" = "ziglang.vscode-zig";
                  };
                };
              };
              rust = {
                extensions = [
                  rust-lang.rust-analyzer
                  vscodeLldb
                ];
                userSettings = {
                  # Rust
                  "rust-analyzer.check.command" = "${pkgs.clippy}/bin/cargo-clippy";
                  "rust-analyzer.inlayHints.enable" = true;
                  "[rust]" = {
                    "editor.defaultFormatter" = "rust-lang.rust-analyzer";
                  };
                };
              };
              golang = {
                extensions = [
                  golang.go
                ];
                userSettings = {
                  "[go]" = {
                    "editor.defaultFormatter" = "golang.go";
                  };
                };
              };
              python = {
                extensions = [
                  # Python core
                  ms-python.python
                  ms-python.vscode-pylance

                  # Jupyter notebooks
                  ms-toolsai.jupyter
                  ms-toolsai.jupyter-keymap
                  ms-toolsai.jupyter-renderers
                ];
                userSettings = {
                  "python.languageServer" = "Pylance";
                  "[python]" = {
                    "editor.defaultFormatter" = "ms-python.python";
                  };
                };
              };
              javaScript = {
                extensions = [
                  dbaeumer.vscode-eslint
                  esbenp.prettier-vscode
                ];
                userSettings = {
                  "[javascript]" = {
                    "editor.defaultFormatter" = "esbenp.prettier-vscode";
                  };
                  "[typescript]" = {
                    "editor.defaultFormatter" = "esbenp.prettier-vscode";
                  };
                };
              };
              ruby = {
                extensions = [
                  shopify.ruby-lsp
                  sorbet.sorbet-vscode-extension
                ];
                userSettings = {
                  "[ruby]" = {
                    "editor.defaultFormatter" = "shopify.ruby-lsp";
                  };
                };
              };
              terraform = {
                extensions = [
                  hashicorp.hcl
                  hashicorp.terraform
                  nandovdk.tflint-vscode
                  tfsec.tfsec
                ];
                userSettings = {
                  "terraform.languageServer.enable" = true;
                  "terraform.languageServer.args" = [ "serve" ];
                  "terraform.validation.enableEnhancedValidation" = true;
                  "[terraform]" = {
                    "editor.defaultFormatter" = "hashicorp.terraform";
                  };
                };
              };
            };
            frameworkExtensions = {
              zmk = {
                extensions = [
                  spadin.zmk-tools
                ];
              };
              svelte = {
                extensions = [
                  svelte.svelte-vscode
                ];
              };
              vue = {
                extensions = [
                  vue.volar
                ];
              };
              ansible = {
                extensions = [
                  redhat.ansible
                ];
                userSettings = {
                  "ansible.ansible.path" = "${pkgs.ansible}/bin/ansible"; # Target ansible binary via nixpkgs
                  "ansible.lightspeed.enabled" = false; # Disable ansible lightspeed features, I don't use them
                };
              };
              containers = {
                extensions = [
                  ms-azuretools.vscode-containers
                  ms-kubernetes-tools.vscode-kubernetes-tools
                ];
                userSettings = {
                  # Container Tools — Docker client
                  "containers.containerClient" = "com.microsoft.visualstudio.containers.docker";
                  "containers.orchestratorClient" = "com.microsoft.visualstudio.orchestrators.dockercompose";

                  # Kubernetes
                  "vs-kubernetes.kubectl-path" = "${pkgs.kubectl}/bin/kubectl";
                  "vscode-kubernetes.helm-path" = "${pkgs.kubernetes-helm}/bin/helm";
                  "vscode-kubernetes.minikube-path" = "${pkgs.minikube}/bin/minikube";
                };
              };
              shopify = {
                extensions = [
                  shopify.theme-check-vscode
                ];
              };
            };
            # lib.recursiveUpdate replaces list-valued attributes wholesale
            # rather than concatenating them, so folding extension modules
            # together with it silently drops every extensions list but the
            # last. Concatenate extensions explicitly and recursively merge
            # userSettings instead.
            mergeVscodeModules = modules: {
              extensions = lib.unique (lib.concatMap (m: m.extensions or [ ]) modules);
              userSettings = lib.foldl' lib.recursiveUpdate { } (map (m: m.userSettings or { }) modules);
            };
            common = mergeVscodeModules [
              {
                extensions = [
                  # Themes + keybindings
                  ms-vscode.atom-keybindings
                  catppuccin.catppuccin-vsc

                  # Docs
                  bierner.markdown-mermaid
                  yzhang.markdown-all-in-one
                  # Excalidraw + Excalimath

                  # Tooling
                  remoteSsh
                  ms-vscode.hexeditor
                  christian-kohler.path-intellisense
                ];
                userSettings = {
                  # Editor appearance — font managed by Stylix. Stylix's own
                  # generated "Stylix" theme is a generic base16-derived
                  # approximation; the dedicated catppuccin-vsc extension
                  # (above) gives real Catppuccin theming, so force the
                  # color theme to its macchiato variant, matching the
                  # scheme set in stylix.base16Scheme on the host. mkForce
                  # is required because stylix also writes this same key
                  # for the profiles listed in stylix.targets.vscode.profileNames.
                  "workbench.colorTheme" = lib.mkForce "Catppuccin Macchiato";
                  "editor.minimap.enabled" = true;
                  "editor.renderWhitespace" = "trailing";
                  "editor.cursorBlinking" = "smooth";
                  "editor.cursorSmoothCaretAnimation" = "on";
                  "editor.smoothScrolling" = true;
                  "editor.bracketPairColorization.enabled" = true;
                  "editor.guides.indentation" = true;
                  "editor.guides.bracketPairs" = true;

                  # General UI/UX improvements
                  "editor.inlineSuggest.enabled" = true;
                  "editor.tabCompletion" = "on";
                  "workbench.startupEditor" = "none";
                  "workbench.editor.closeOnFileDelete" = false;

                  # Formatting
                  "editor.tabSize" = 2;
                  "editor.formatOnSave" = true;
                  "editor.formatOnPaste" = true;
                  "editor.codeActionsOnSave" = {
                    "source.fixAll" = "explicit";
                    "source.organizeImports" = "explicit";
                  };

                  # Files
                  "files.autoSave" = "afterDelay";
                  "files.autoSaveDelay" = 1000;
                  "files.trimTrailingWhitespace" = true;
                  "files.insertFinalNewline" = true;
                  "files.trimFinalNewlines" = true;

                  # Search
                  "search.exclude" = {
                    "**/.direnv" = true;
                    "**/result" = true;
                    "**/node_modules" = true;
                    "**/.git" = true;
                  };

                  # Terminal
                  "terminal.integrated.cursorBlinking" = true;

                  # Git
                  "git.autofetch" = true;
                  "git.confirmSync" = false;
                  "git.enableSmartCommit" = true;

                  # Disable extension updates
                  "extensions.autoCheckUpdates" = false;
                  "extensions.autoUpdate" = "off";
                  "accessibility.signals.terminalBell" = {
                    "sound" = "off";
                  };

                  # Markdown settings
                  "[markdown]" = {
                    "editor.wordWrap" = "on";
                    "editor.quickSuggestions" = {
                      "comments" = "on";
                      "strings" = "on";
                      "other" = "on";
                    };
                  };
                };
              }
              languageExtensions.configurationLanguages
              languageExtensions.nix
              languageExtensions.bash
            ];
          in
          {
            /**
              * Default profile for VSCode.
              * Just the shared base: themes/tooling extensions, editor,
              * formatting, and git settings. No language-specific tooling.
            */
            default = common;
            /**
              * Embedded profile for VSCode
              * Includes extensions and settings for:
              * - C/C++ (CMake / Clangd / LLDB)
              * - Zig
              * - Rust
              * - ZMK firmware development
              * - Devicetree / Kconfig development (Firmware & Kernel build tooling)
            */
            systems = mergeVscodeModules [
              common
              {
                extensions = [
                  # Firmware & Build tooling (Devicetree / Kconfig)
                  trond-snekvik.devicetree
                  trond-snekvik.kconfig-lang
                ];
              }
              languageExtensions.cpp
              languageExtensions.zig
              languageExtensions.rust
              frameworkExtensions.zmk
            ];
            /**
              * DevOps profile for VSCode
              * Includes extensions and settings for:
              * - Nix
              * - Bash
              * - Configuration languages (YAML / TOML / XML)
              * - Ansible
              * - Terraform
              * - Containers (Docker / Kubernetes)
            */
            devOps = mergeVscodeModules [
              common
              languageExtensions.golang
              languageExtensions.python
              languageExtensions.terraform
              frameworkExtensions.ansible
              frameworkExtensions.containers
            ];
            /**
              * Data Science profile for VSCode
              * Includes extensions and settings for:
              * - Python
            */
            dataScience = mergeVscodeModules [
              common
              languageExtensions.python
            ];
            /**
              * Fullstack profile for VSCode
              * Includes extensions and settings for:
              * - JavaScript / TypeScript
            */
            fullstack = mergeVscodeModules [
              common
              languageExtensions.javaScript
            ];
          };
      };
    };
  };
}
