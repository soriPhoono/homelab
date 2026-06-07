{
  lib,
  config,
  options,
  pkgs,
  ...
}: let
  cfg = config.hosting.hermes-agent;
in
  with lib; {
    options.hosting.hermes-agent = {
      enable = mkEnableOption ''
        the Hermes AI agent service. Hermes is a self-improving AI agent
        by Nous Research with persistent memory, agent-created skills, and
        a messaging gateway supporting 21+ platforms. It runs inside an OCI
        container (Docker or Podman) for full self-modification support,
        including runtime package installation via apt/pip/npm.

        When enabled, the module:
        - Creates the hermes system user and state directory
        - Generates config.yaml from declarative settings
        - Wires sops-nix secrets (API keys, tokens) via environmentFiles
        - Starts the hermes gateway inside a container as a systemd service
        - Optionally adds the hermes CLI to system PATH
        - Optionally creates ~/.hermes symlinks for host users
      '';

      model = mkOption {
        type = types.str;
        default = "anthropic/claude-sonnet-4";
        example = "google/gemini-3-flash";
        description = ''
          The default LLM model identifier for Hermes. Uses the model ID format
          expected by your provider. With OpenRouter (the default when no
          baseUrl is set), models look like "anthropic/claude-sonnet-4" or
          "google/gemini-3-flash". With a direct provider, use their native IDs
          (e.g., "claude-sonnet-4-20250514" for Anthropic).
        '';
      };

      provider = {
        baseUrl = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "https://openrouter.ai/api/v1";
          description = ''
            Custom API base URL for the LLM provider. When unset, Hermes
            defaults to OpenRouter. Set this if you use Anthropic directly,
            OpenAI, or a self-hosted endpoint.
          '';
        };
      };

      environment = mkOption {
        type = types.attrsOf types.str;
        default = {};
        example = {
          HERMES_LOG_LEVEL = "debug";
          TERMINAL_SSH_HOST = "build-server.internal";
        };
        description = ''
          Non-secret environment variables to include in the hermes .env file.
          These are written to the state directory's .env alongside the
          sops-managed secrets. Use this for configuration that doesn't need
          encryption, such as log levels or non-sensitive endpoints.

          For API keys and tokens, use the secrets option instead.
        '';
      };

      secrets = mkOption {
        type = types.attrsOf (
          types.submodule {
            options = {
              sopsFile = mkOption {
                type = types.nullOr types.path;
                default = null;
                description = ''
                  Path to the sops-encrypted file containing this secret.
                  Defaults to the system's defaultSopsFile.
                '';
              };

              format = mkOption {
                type = types.enum [
                  "yaml"
                  "json"
                  "binary"
                  "dotenv"
                ];
                default = "yaml";
                description = ''
                  Format of the sops-encrypted secret file. The content should be
                  a multi-line string of KEY=VALUE pairs. For example:

                  ```
                  OPENROUTER_API_KEY=sk-or-...
                  ANTHROPIC_API_KEY=sk-ant-...
                  TELEGRAM_BOT_TOKEN=123456:ABC...
                  DISCORD_BOT_TOKEN=...
                  ```
                '';
              };
            };
          }
        );
        default = {};
        description = ''
          Sops-managed secrets to expose to the Hermes agent. Each secret
          is decrypted at build time and exposed as an environment file
          referenced by the hermes systemd service.

          The default "hosting/hermes-env" secret is automatically configured if
          secrets are enabled. Add additional secrets for platform tokens,
          API keys for third-party services, or any sensitive values the
          agent needs.
        '';
      };

      lsp = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Enable LSP (Language Server Protocol) support for semantic
            diagnostics. When enabled, Hermes spawns language servers to
            provide real-time code diagnostics after file writes. Supported
            languages include Python, TypeScript, Go, Rust, Nix, and many
            more — see the upstream documentation for the full list.

            Set to false to disable the entire LSP subsystem. The agent falls
            back to in-process syntax checks.
          '';
        };

        installStrategy = mkOption {
          type = types.enum [
            "auto"
            "manual"
          ];
          default = "auto";
          description = ''
            How to handle missing LSP server binaries.

            - "auto": Install missing servers via npm/pip/go install into
              ~/.hermes/lsp/bin.
            - "manual": Only use binaries already on PATH. Skip servers whose
              binaries are not found.
          '';
        };

        waitMode = mkOption {
          type = types.enum [
            "document"
            "full"
          ];
          default = "document";
          description = ''
            How long to wait for LSP diagnostics after each file write.

            - "document": Wait for diagnostics on the saved file only.
            - "full": Wait for diagnostics across the entire project.
          '';
        };

        waitTimeout = mkOption {
          type = types.float;
          default = 5.0;
          description = "Maximum time in seconds to wait for LSP diagnostics to arrive after a file write.";
        };

        servers = mkOption {
          type = types.attrsOf (
            types.submodule {
              options = {
                disable = mkOption {
                  type = types.bool;
                  default = false;
                  description = ''
                    Disable this LSP server entirely. Useful for skipping a
                    language server without disabling the whole subsystem.
                    Example: disabling rust-analyzer on systems without Rust.
                  '';
                };

                command = mkOption {
                  type = types.nullOr (types.listOf types.str);
                  default = null;
                  example = [
                    "/path/to/pyright-langserver"
                    "--stdio"
                  ];
                  description = ''
                    Custom binary path and arguments for the LSP server. Setting
                    this bypasses auto-install entirely. Useful for pinning a
                    specific version or using a wrapper script.
                  '';
                };

                env = mkOption {
                  type = types.attrsOf types.str;
                  default = {};
                  example = {
                    PYRIGHT_LOG_LEVEL = "info";
                  };
                  description = "Extra environment variables passed to the LSP server process.";
                };

                initializationOptions = mkOption {
                  type = types.attrsOf types.anything;
                  default = {};
                  example = {
                    python.analysis.typeCheckingMode = "strict";
                  };
                  description = ''
                    Additional LSP initializationOptions merged into the
                    initialize handshake. Consult your language server's
                    documentation for available options.
                  '';
                };
              };
            }
          );
          default = {};
          example = {
            pyright = {
              initializationOptions = {
                python.analysis.typeCheckingMode = "strict";
              };
            };
            rust-analyzer.disable = true;
          };
          description = ''
            Per-language LSP server overrides. Each key corresponds to a
            language server name recognized by Hermes (e.g., pyright,
            typescript, rust-analyzer, gopls, nil (Nix), etc.). Use this
            to customize server behavior, pin specific binaries, or disable
            servers you don't need.
          '';
        };
      };

      mcpServers = mkOption {
        type = types.attrsOf (
          types.submodule {
            options = {
              enabled = mkOption {
                type = types.bool;
                default = true;
                description = ''
                  Enable or disable this MCP server. Set to false to keep the
                  configuration but prevent the server from connecting.
                '';
              };

              command = mkOption {
                type = types.nullOr types.str;
                default = null;
                example = "npx";
                description = ''
                  Executable to run for stdio-transport MCP servers. Common
                  choices are "npx" (Node.js), "uvx" (Python), or a direct
                  binary path.
                '';
              };

              args = mkOption {
                type = types.listOf types.str;
                default = [];
                example = [
                  "-y"
                  "@modelcontextprotocol/server-filesystem"
                  "/data/workspace"
                ];
                description = "Command-line arguments passed to the MCP server executable.";
              };

              env = mkOption {
                type = types.attrsOf types.str;
                default = {};
                example = {
                  GITHUB_PERSONAL_ACCESS_CREDENTIAL = "\${GITHUB_TOKEN}";
                };
                description = ''
                  Environment variables for the MCP server process. Values are
                  resolved from $HERMES_HOME/.env at runtime, so you can
                  reference secrets like \${GITHUB_TOKEN} that are injected via
                  sops-nix. Never put tokens directly in Nix configuration.
                '';
              };

              url = mkOption {
                type = types.nullOr types.str;
                default = null;
                example = "https://mcp.example.com/v1/mcp";
                description = ''
                  Server endpoint URL for HTTP/StreamableHTTP transport MCP
                  servers. Set this for remote MCP servers instead of command.
                '';
              };

              headers = mkOption {
                type = types.attrsOf types.str;
                default = {};
                example = {
                  Authorization = "Bearer \${MCP_API_KEY}";
                };
                description = ''
                  HTTP headers sent with every request to a remote MCP server.
                  Use environment variable references (\${VAR}) for secrets.
                '';
              };

              timeout = mkOption {
                type = types.nullOr types.int;
                default = null;
                description = "Per-tool-call timeout in seconds (default: 120).";
              };

              connectTimeout = mkOption {
                type = types.nullOr types.int;
                default = null;
                description = "Initial connection timeout in seconds (default: 60).";
              };

              auth = mkOption {
                type = types.nullOr (types.enum ["oauth"]);
                default = null;
                description = ''
                  Authentication method for HTTP MCP servers. Set to "oauth" to
                  enable OAuth 2.1 with PKCE flow. Tokens are persisted in
                  $HERMES_HOME/mcp-tokens/<server-name>.json.
                '';
              };

              tools = mkOption {
                type = types.nullOr (
                  types.submodule {
                    options = {
                      include = mkOption {
                        type = types.nullOr (types.either types.str (types.listOf types.str));
                        default = null;
                        description = "Whitelist of server-native MCP tools to expose.";
                      };
                      exclude = mkOption {
                        type = types.nullOr (types.either types.str (types.listOf types.str));
                        default = null;
                        description = "Blacklist of server-native MCP tools to hide.";
                      };
                      resources = mkOption {
                        type = types.nullOr types.bool;
                        default = null;
                        description = "Enable or disable list_resources + read_resource.";
                      };
                      prompts = mkOption {
                        type = types.nullOr types.bool;
                        default = null;
                        description = "Enable or disable list_prompts + get_prompt.";
                      };
                    };
                  }
                );
                default = null;
                description = ''
                  Tool filtering policy for this MCP server. Controls which
                  tools, resources, and prompts are exposed to the agent.
                '';
              };

              sampling = mkOption {
                type = types.nullOr (
                  types.submodule {
                    options = {
                      enabled = mkOption {
                        type = types.bool;
                        default = true;
                        description = "Enable server-initiated LLM requests.";
                      };
                      model = mkOption {
                        type = types.nullOr types.str;
                        default = null;
                        description = "Model override for server-initiated requests.";
                      };
                      maxTokensCap = mkOption {
                        type = types.nullOr types.int;
                        default = null;
                        description = "Maximum tokens per sampling request.";
                      };
                      timeout = mkOption {
                        type = types.nullOr types.int;
                        default = null;
                        description = "Timeout in seconds for sampling requests.";
                      };
                      maxRpm = mkOption {
                        type = types.nullOr types.int;
                        default = null;
                        description = "Maximum requests per minute for sampling.";
                      };
                    };
                  }
                );
                default = null;
                description = ''
                  Sampling configuration for server-initiated LLM requests.
                  Some MCP servers can request LLM completions from the agent.
                  This controls the policy for such requests.
                '';
              };
            };
          }
        );
        default = {};
        example = {
          filesystem = {
            command = "npx";
            args = [
              "-y"
              "@modelcontextprotocol/server-filesystem"
              "/data/workspace"
            ];
          };
          github = {
            command = "npx";
            args = [
              "-y"
              "@modelcontextprotocol/server-github"
            ];
            env = {
              GITHUB_TOKEN = "\${GITHUB_PERSONAL_ACCESS_TOKEN}";
            };
            tools = {
              include = [
                "list_issues"
                "create_issue"
                "search_code"
              ];
              resources = false;
              prompts = false;
            };
          };
        };
        description = ''
          MCP (Model Context Protocol) server definitions. Each server
          provides tools, resources, and prompts that extend the agent's
          capabilities. Supports both stdio (local command) and HTTP
          (remote URL) transports.

          Environment variables in env values are resolved from
          $HERMES_HOME/.env at runtime. Use the secrets option to inject
          sensitive values — never put tokens directly in Nix configuration.
        '';
      };

      extraDependencyGroups = mkOption {
        type = types.listOf types.str;
        default = [];
        example = [
          "messaging"
          "hindsight"
        ];
        description = ''
          Optional Python dependency groups to include from hermes-agent's
          pyproject.toml. These are resolved by uv at build time alongside
          core dependencies. Available groups include:

          - "messaging": Discord, Telegram, Slack
          - "matrix": Matrix/Element
          - "voice": Local speech-to-text (faster-whisper)
          - "edge-tts": Edge TTS provider
          - "hindsight": Hindsight memory provider
          - "honcho": Honcho memory provider
          - "anthropic": Native Anthropic SDK
          - "bedrock": AWS Bedrock
          - "exa": Exa web search
          - "firecrawl": Firecrawl web search
          - "fal": FAL image generation

          Use the pre-built #messaging or #full flake packages instead of
          per-extra configuration when you need multiple groups.
        '';
      };

      extraPackages = mkOption {
        type = types.listOf types.package;
        default = [];
        example = lib.literalExpression "[ pkgs.pandoc pkgs.imagemagick pkgs.jq ]";
        description = ''
          Extra system packages to make available to the hermes agent on PATH.
          These are added to the service's PATH via --suffix, so they are
          available to terminal commands and tool execution.
        '';
      };

      extraArgs = mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["--verbose"];
        description = "Extra CLI arguments passed to the hermes gateway process.";
      };

      settings = mkOption {
        type = types.attrsOf types.anything;
        default = {};
        example = {
          display.personality = "kawaii";
          memory.memory_enabled = true;
          terminal.backend = "local";
          compression.enabled = true;
        };
        description = ''
          Additional settings deep-merged into hermes config.yaml. These
          correspond 1:1 with the YAML keys in ~/.hermes/config.yaml.

          Nix-declared keys always win over keys in an existing config.yaml,
          but user-added keys that Nix doesn't touch are preserved. This means
          manual edits or agent-created settings (like disabled skills or
          streaming config) survive nixos-rebuild switch.

          For the authoritative list of config keys, run:
          nix build .#configKeys && cat result
        '';
      };

      documents = mkOption {
        type = types.attrsOf (types.either types.str types.path);
        default = {};
        example = {
          "USER.md" = ./documents/USER.md;
          "README.md" = lib.literalExpression ''"# Project Workspace"'';
        };
        description = ''
          Files to install into the agent's working directory. Hermes reads
          specific files by convention (USER.md for user context, etc.).

          Values can be path references (copied from the Nix store) or inline
          strings. Files are installed on every nixos-rebuild switch.

          Note: The agent's primary persona file (SOUL.md) lives at
          $HERMES_HOME/SOUL.md in the state directory, separate from
          documents. Put SOUL.md in stateDir itself, not in documents.
        '';
      };

      addToSystemPackages = mkOption {
        type = types.bool;
        default = true;
        description = ''
          When enabled, adds the hermes CLI to the system-wide PATH and sets
          HERMES_HOME system-wide. This lets all users run `hermes` commands
          that share state (sessions, skills, cron) with the gateway service.

          Without this, users get a separate ~/.hermes/ directory and the CLI
          is isolated from the service.
        '';
      };

      stateDir = mkOption {
        type = types.str;
        default = "/var/lib/hermes";
        description = "State directory for hermes data (config, memories, sessions).";
      };

      hostUsers = mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["sphoono"];
        description = ''
          Interactive users to add to the hermes group and create a ~/.hermes
          symlink pointing to the service state directory. This gives them
          access so CLI commands (hermes chat, hermes setup --portal) share
          state with the gateway service running in the container.
        '';
      };

      # ── Portal / Subscription ────────────────────
      portal = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Enable Nous Portal as the default provider.  The Portal bundles
            300+ models plus the Tool Gateway (web search, image generation,
            TTS, cloud browser) under one OAuth-based subscription.

            When enabled, Hermes uses Portal OAuth tokens instead of raw API
            keys.  Tokens are persisted in auth.json inside the state
            directory.

            For initial setup you may still need to run:
              hermes setup --portal
            interactively to complete the OAuth handshake.
          '';
        };
      };

      # ── Web Dashboard ────────────────────────────
      dashboard = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Run the Hermes web dashboard as a supervised systemd service.
            The dashboard is a FastAPI web server serving a React frontend
            at http://{host}:{port}.  It provides:

            - Session browser and management
            - Configuration editor (settings, API keys, models)
            - In-browser chat terminal (with --tui flag or HERMES_DASHBOARD_TUI=1)
            - Cron job management
            - Metrics and logs

            Requires the dashboard to complete its first-time setup:
              hermes dashboard
            before the service will function.
          '';
        };

        port = mkOption {
          type = types.port;
          default = 9119;
          description = ''
            Port for the web dashboard HTTP server.  Defaults to 9119 which
            is the standard Hermes dashboard port.
          '';
        };

        host = mkOption {
          type = types.str;
          default = "127.0.0.1";
          description = ''
            Bind address for the web dashboard.

            - "127.0.0.1" (default): Local only.  Access via localhost proxy
              or SSH tunnel.
            - "0.0.0.0": All interfaces.  Engages the OAuth auth gate for
              non-loopback binds.  Requires Portal OAuth or basic auth
              credentials configured.
            - Tailscale IP: Bind to your tailnet address for VPN-only access.

            WARNING: Binding to 0.0.0.0 or a non-loopback address without
            authentication exposes the dashboard (including API keys and
            session data) to anyone on the network.
          '';
        };

        openBrowser = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Auto-open the browser when the dashboard starts.  Only meaningful
            for interactive use — has no effect when run as a systemd service.
          '';
        };

        enableChat = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Expose the in-browser Chat tab (embedded TUI via PTY/WebSocket).
            Requires the --tui flag or HERMES_DASHBOARD_TUI=1 environment
            variable.  Set to false if you don't need the chat terminal in
            the dashboard.
          '';
        };
      };

      # ── Gateway API ──────────────────────────────
      gateway = {
        enableApi = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Expose the gateway's OpenAI-compatible API server.  When enabled,
            the gateway listens for HTTP API requests in addition to its
            messaging-platform connections.
          '';
        };

        apiPort = mkOption {
          type = types.port;
          default = 8642;
          description = ''
            Port for the gateway's OpenAI-compatible API server.  Defaults
            to 8642 which is the standard Hermes gateway API port.
          '';
        };
      };

      # ── Container ──────────────────────────────
      container = {
        backend = mkOption {
          type = types.enum ["docker" "podman"];
          default = "docker";
          description = ''
            Container runtime backend. Docker is the default. Change to
            "podman" for rootless container operation.

            The required runtime is automatically enabled on the host via
            virtualisation.docker or virtualisation.podman unless
            autoEnableRuntime is set to false.
          '';
        };

        image = mkOption {
          type = types.str;
          default = "ubuntu:24.04";
          description = ''
            OCI container image for the Hermes agent runtime. The image is
            pulled at container start via the configured backend.

            The default ubuntu:24.04 provides apt, pip, and npm for runtime
            self-modification. Custom images should include Python 3.12+
            and the tools the agent needs to install packages.
          '';
        };

        extraVolumes = mkOption {
          type = types.listOf types.str;
          default = [];
          example = ["/home/user/projects:/projects:rw"];
          description = ''
            Extra volume mounts passed to the container runtime in
            host:container:mode format. Useful for giving the agent access
            to project directories, datasets, or other host paths.

            The state directory and secrets are mounted automatically.
          '';
        };

        extraOptions = mkOption {
          type = types.listOf types.str;
          default = [];
          example = ["--gpus" "all"];
          description = ''
            Extra arguments passed to docker/podman create. Useful for GPU
            passthrough (--gpus all), resource limits, or custom network
            configuration.
          '';
        };

        autoEnableRuntime = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Automatically enable the container runtime on the host system.
            When true, enables virtualisation.docker or virtualisation.podman
            based on the configured backend.

            Set to false if you manage the runtime separately or want to
            configure it with custom options.
          '';
        };
      };

      # ── Proxy Integration ───────────────────────
      enableProxy = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Register the Hermes agent with the hosting proxy module, making it
          accessible at <subdomain>.<localDomain>/<path>.  The proxy routes
          traffic to the Hermes web dashboard on the configured port.

          Requires hosting.proxy.enable = true and dashboard.enable = true
          to serve actual content.
        '';
      };

      proxy = {
        subdomain = mkOption {
          type = types.str;
          default = "ai";
          description = ''
            Subdomain to use when registering with the proxy module.
            Defaults to "ai" so Hermes is accessible at
            https://<subdomain>.<localDomain>/<path>.
          '';
        };

        path = mkOption {
          type = types.str;
          default = "/hermes";
          description = ''
            Path prefix to use when registering with the proxy module.
            The Hermes dashboard will be accessible at
            https://<subdomain>.<localDomain><path>.
          '';
        };
      };
    };

    config = mkIf cfg.enable (mkMerge [
      # ──────────────────────────────────────────────
      # 1. Core service configuration
      # ──────────────────────────────────────────────
      {
        services.hermes-agent = {
          enable = true;

          # OCI container mode — enables runtime self-modification (apt/pip/npm)
          container.enable = true;
          container.backend = cfg.container.backend;
          container.image = cfg.container.image;
          container.extraVolumes = cfg.container.extraVolumes;
          container.extraOptions = cfg.container.extraOptions;

          # Add CLI to PATH and set HERMES_HOME system-wide
          inherit (cfg) addToSystemPackages;

          # State directory
          inherit (cfg) stateDir;

          # Additional CLI args
          inherit (cfg) extraArgs;

          # Extra system packages
          inherit (cfg) extraPackages;

          # Python dependency groups
          inherit (cfg) extraDependencyGroups;

          # Workspace documents
          inherit (cfg) documents;

          # Deep-merged settings: start with generated options, then overlay
          # user-provided settings on top. The upstream module handles the
          # deep merge via the deepConfigType.
          settings =
            recursiveUpdate (filterAttrsRecursive (_n: v: v != null) {
              # Model configuration
              model.default = cfg.model;
              model.base_url = cfg.provider.baseUrl;

              # LSP subsystem
              lsp.enabled = cfg.lsp.enable;
              lsp.install_strategy = cfg.lsp.installStrategy;
              lsp.wait_mode = cfg.lsp.waitMode;
              lsp.wait_timeout = cfg.lsp.waitTimeout;

              # Per-server LSP overrides
              lsp.servers =
                mapAttrs
                (
                  _name: server:
                    filterAttrsRecursive (_n: v: v != null) {
                      disabled = server.disable;
                      inherit (server) command;
                      env =
                        if server.env != {}
                        then server.env
                        else null;
                      initialization_options =
                        if server.initializationOptions != {}
                        then server.initializationOptions
                        else null;
                    }
                )
                (
                  filterAttrs (
                    _n: server:
                      server.disable || server.command != null || server.env != {} || server.initializationOptions != {}
                  )
                  cfg.lsp.servers
                );
            })
            cfg.settings;

          # MCP server definitions
          mcpServers =
            mapAttrs (
              _name: server:
                filterAttrsRecursive (_n: v: v != null) {
                  inherit
                    (server)
                    enabled
                    command
                    args
                    env
                    url
                    headers
                    auth
                    sampling
                    ;
                  tools =
                    if server.tools != null
                    then
                      filterAttrsRecursive (_n: v: v != null) {
                        inherit (server.tools) include exclude;
                      }
                    else null;
                  inherit (server) timeout;
                  connect_timeout = server.connectTimeout;
                }
            )
            cfg.mcpServers;

          # Non-secret environment
          inherit (cfg) environment;
        };

        # Ensure files inside .hermes are group-readable so users in the
        # hermes group can run the CLI (chat, TUI, setup --portal) without
        # permission errors on runtime files (auth.lock, .env, state.db,
        # sessions, etc.).
        #
        # - Z: recursively fix permissions on all existing content
        # - A: set default ACL so new files inherit group read/write (rw)
        systemd.tmpfiles.rules = [
          "Z ${cfg.stateDir}/.hermes 2770 ${config.services.hermes-agent.user} ${config.services.hermes-agent.group} -"
          "A ${cfg.stateDir}/.hermes - - - - d:${config.services.hermes-agent.group}:rwX"
        ];
      }

      # ──────────────────────────────────────────────
      # 2. Container runtime
      # ──────────────────────────────────────────────
      (mkIf cfg.container.autoEnableRuntime (
        let
          isDocker = cfg.container.backend != "podman";
          runtimeName =
            if isDocker
            then "docker"
            else "podman";
        in {
          # Enable the container runtime on the host
          virtualisation.${runtimeName}.enable = true;

          # The hermes system user needs access to the container runtime
          # socket so the CLI wrapper (and dashboard) can docker exec into
          # the container. The docker/podman group is created by the
          # virtualisation module above.
          users.users.${
            config.services.hermes-agent.user
          }.extraGroups = [runtimeName];

          # The dashboard service runs in a sandboxed systemd PATH that
          # doesn't include /run/current-system/sw/bin. Without the
          # container runtime on PATH, the hermes CLI wrapper cannot
          # route commands into the container.
          systemd.services.hermes-dashboard = lib.mkIf cfg.dashboard.enable {
            serviceConfig.Environment = [
              "PATH=/run/current-system/sw/bin"
            ];
          };

          # Expose host-side service ports from the container so the
          # dashboard and gateway API are reachable from the host.
          # The hermes CLI routes `hermes dashboard` into the container
          # via docker exec, but port publishing must be set at container
          # creation time — these mappings ensure the ports are accessible.
          services.hermes-agent.container.extraOptions =
            (lib.optionals cfg.dashboard.enable [
              "-p"
              "${toString cfg.dashboard.port}:${toString cfg.dashboard.port}"
            ])
            ++ (lib.optionals cfg.gateway.enableApi [
              "-p"
              "${toString cfg.gateway.apiPort}:${toString cfg.gateway.apiPort}"
            ]);
        }
      ))

      # ──────────────────────────────────────────────
      # 3. Host user access
      # ──────────────────────────────────────────────
      (mkIf (cfg.hostUsers != []) {
        services.hermes-agent.container.hostUsers = cfg.hostUsers;
      })

      # ──────────────────────────────────────────────
      # 4. Web Dashboard service
      # ──────────────────────────────────────────────
      (mkIf cfg.dashboard.enable {
        systemd.services.hermes-dashboard = {
          description = "Hermes Agent Web Dashboard";
          after = [
            "network.target"
            "hermes-agent.service"
          ];
          wants = ["hermes-agent.service"];
          wantedBy = ["multi-user.target"];

          serviceConfig = {
            Type = "simple";
            User = config.services.hermes-agent.user;
            Group = config.services.hermes-agent.group;
            WorkingDirectory = config.services.hermes-agent.stateDir;

            # Inherit the same environment as the gateway
            EnvironmentFile = config.services.hermes-agent.environmentFiles;

            # Fix group permissions on state files so host users (like
            # sphoono in the hermes group) can run `hermes setup --portal`
            # and other CLI commands that read ~/.hermes/.env.
            #
            # The `-` prefix tells systemd to ignore non-zero exits
            # (files may not exist yet before first container run).
            ExecStartPre = [
              "-${pkgs.coreutils}/bin/chmod"
              "g+rwX"
              "${cfg.stateDir}/.hermes"
              "${cfg.stateDir}/.hermes/.env"
              "${cfg.stateDir}/.hermes/config.yaml"
            ];

            ExecStart = ''
              ${config.services.hermes-agent.package}/bin/hermes \
                ${lib.optionalString cfg.dashboard.enableChat "--tui"} \
                dashboard \
                --host ${cfg.dashboard.host} \
                --port ${toString cfg.dashboard.port}
            '';

            Restart = "on-failure";
            RestartSec = 5;

            # Hardening
            NoNewPrivileges = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;

            # ProtectSystem=strict makes / read-only. The state directory
            # needs to be writable so host users can access ~/.hermes files
            # and so the ExecStartPre chmod can fix group permissions.
            ReadWritePaths = [cfg.stateDir];
          };
        };
      })

      # ──────────────────────────────────────────────
      # 5. Portal / Subscription configuration
      # ──────────────────────────────────────────────
      (mkIf cfg.portal.enable {
        services.hermes-agent.settings = {
          # Switch the default model provider to Nous Portal
          model.provider = "nous";
        };

        services.hermes-agent.environment =
          (cfg.environment or {})
          // {
            HERMES_PORTAL_ENABLED = "1";
          };
      })

      # ──────────────────────────────────────────────
      # 6. Proxy integration
      # ──────────────────────────────────────────────
      (mkIf cfg.enableProxy {
        hosting.proxy.services.${cfg.proxy.subdomain} = {
          name = "Hermes AI Agent";
          description = ''
            Hermes is a self-improving AI agent built by Nous Research with
            persistent memory, agent-created skills, and a messaging gateway
            supporting 21+ platforms.  This routes traffic to the Hermes web
            dashboard on port ${toString cfg.dashboard.port}.
          '';
          proxyPort = cfg.dashboard.port;
          # Rewrite Host header to 127.0.0.1 so the dashboard's FastAPI
          # host-header validation accepts requests forwarded by Caddy.
          extraConfig = ''
            header_up Host 127.0.0.1
          '';
          extraPaths = {
            "${cfg.proxy.path}" = {
              name = "Hermes Agent Web Dashboard";
              description = ''
                Hermes Agent web dashboard — browser-based UI for managing
                configuration, API keys, sessions, cron jobs, and chatting
                with the agent.  Powered by FastAPI + React.
              '';
              proxyPort = cfg.dashboard.port;
              handlePath = true;
              extraConfig = ''
                header_up Host 127.0.0.1
              '';
            };
          };
        };
      })

      # ──────────────────────────────────────────────
      # 7. SOPS secrets integration
      # ──────────────────────────────────────────────
      (mkIf (options ? sops) {
        sops.secrets."hosting/hermes-env" = {};

        services.hermes-agent.environmentFiles = let
          userSecrets = mapAttrsToList (name: _secret: config.sops.secrets.${name}.path) cfg.secrets;
          defaultSecret = [
            config.sops.secrets."hosting/hermes-env".path
          ];
        in
          if cfg.secrets != {}
          then userSecrets
          else defaultSecret;
      })
    ]);
  }
