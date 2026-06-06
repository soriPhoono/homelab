# Hermes Agent — NixOS Hosting Module

## Overview

The `hosting.hermes-agent` module deploys a **Hermes AI agent** by Nous Research as a native systemd service on NixOS. Hermes is a self-improving AI agent with persistent memory, agent-created skills, a messaging gateway (21+ platforms), and a built-in learning loop.

This NixOS module wraps the upstream `services.hermes-agent` from [github:NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent) with project-specific conventions, sops-nix secrets integration, and sensible defaults.

______________________________________________________________________

## Quick Start

### 1. Enable the module in your system configuration

```nix
{
  hosting.hermes-agent.enable = true;
}
```

This minimal configuration:

- Creates the `hermes` system user and `/var/lib/hermes/` state directory
- Generates `config.yaml` from declarative settings
- Wires sops-nix secrets (expects a `hermes/env` secret)
- Starts the Hermes gateway as a systemd service
- Adds the `hermes` CLI to the system PATH

### 2. Create a sops-encrypted secrets file

Hermes needs at least one LLM provider API key to function. Create a sops-encrypted environment file at your system's `secrets.yml`:

```yaml
# secrets/hermes.yml (or your system's secrets file)
hermes/env: |
  OPENROUTER_API_KEY=sk-or-...
  ANTHROPIC_API_KEY=sk-ant-...
  TELEGRAM_BOT_TOKEN=123456:ABC...
  DISCORD_BOT_TOKEN=...
```

Encrypt with:

```bash
sops encrypt --in-place secrets/hermes.yml
```

### 3. Rebuild and verify

```bash
sudo nh os switch .
systemctl status hermes-agent
journalctl -u hermes-agent -f
```

### 4. Talk to your agent

```bash
hermes chat
```

______________________________________________________________________

## Configuration Reference

### Master Switch

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `hosting.hermes-agent.enable` | `bool` | `false` | Enable the Hermes AI agent service |

### Model & Provider

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `model` | `str` | `"anthropic/claude-sonnet-4"` | Default LLM model identifier |
| `provider.baseUrl` | `null or str` | `null` | Custom API base URL (null = OpenRouter) |

With OpenRouter (default), model IDs look like `"anthropic/claude-sonnet-4"` or `"google/gemini-3-flash"`. With a direct provider, use their native IDs (e.g., `"claude-sonnet-4-20250514"` for Anthropic).

### Secrets

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `secrets` | `attrsOf submodule` | `{}` | Sops-managed secrets for the agent |
| `secrets.<name>.sopsFile` | `path or null` | `null` | Path to the sops-encrypted file |
| `secrets.<name>.format` | `enum` | `"yaml"` | File format (yaml, json, binary, dotenv) |

The default `hermes/env` secret is automatically configured. Each secret should contain `KEY=VALUE` pairs that are loaded into the agent's environment at runtime.

#### Typical secrets

```
OPENROUTER_API_KEY=sk-or-...          # LLM provider (required)
ANTHROPIC_API_KEY=sk-ant-...          # Direct Anthropic (optional)
TELEGRAM_BOT_TOKEN=123456:ABC...      # Telegram gateway
DISCORD_BOT_TOKEN=...                 # Discord gateway
SLACK_BOT_TOKEN=...                   # Slack gateway
GOOGLE_API_KEY=...                    # Google/Gemini provider
GITHUB_TOKEN=ghp_...                  # GitHub MCP server
```

### Non-Secret Environment

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `environment` | `attrsOf str` | `{}` | Non-secret environment variables |

```nix
{
  hosting.hermes-agent.environment = {
    HERMES_LOG_LEVEL = "debug";
    TERMINAL_SSH_HOST = "build-server.internal";
  };
}
```

### LSP (Language Server Protocol)

The LSP subsystem provides real-time code diagnostics after file writes. Hermes spawns language servers for supported languages and reports diagnostics to the model.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `lsp.enable` | `bool` | `true` | Enable LSP diagnostics |
| `lsp.installStrategy` | `"auto" or "manual"` | `"auto"` | Auto-install missing servers or use PATH only |
| `lsp.waitMode` | `"document" or "full"` | `"document"` | Wait for single-file or full-project diagnostics |
| `lsp.waitTimeout` | `float` | `5.0` | Max seconds to wait for diagnostics |
| `lsp.servers` | `attrsOf submodule` | `{}` | Per-server overrides |

#### Supported Languages

| Language | Server | Auto-install |
|----------|--------|-------------|
| Python | `pyright-langserver` | npm |
| TypeScript / JSX / TSX | `typescript-language-server` | npm |
| Go | `gopls` | `go install` |
| Rust | `rust-analyzer` | manual |
| Nix | `nixd` | manual |
| C / C++ | `clangd` | manual |
| Bash / Zsh | `bash-language-server` | npm |
| YAML | `yaml-language-server` | npm |
| Lua | `lua-language-server` | manual |
| Vue | `@vue/language-server` | npm |
| Svelte | `svelte-language-server` | npm |
| Terraform | `terraform-ls` | manual |
| Dockerfile | `dockerfile-language-server-nodejs` | npm |
| PHP | `intelephense` | npm |
| JSON | Built-in | — |

#### LSP Server Overrides

```nix
{
  hosting.hermes-agent.lsp.servers = {
    pyright = {
      initializationOptions = {
        python.analysis.typeCheckingMode = "strict";
      };
    };
    rust-analyzer = {
      disable = true;  # Skip Rust if not needed
    };
    typescript = {
      command = ["/custom/path/to/typescript-language-server" "--stdio"];
    };
  };
}
```

### MCP Servers

MCP (Model Context Protocol) servers extend the agent's capabilities with external tools, file system access, API integrations, and more.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `mcpServers` | `attrsOf submodule` | `{}` | MCP server definitions |

Each server supports either **stdio** (local command) or **HTTP** (remote URL) transport.

#### Stdio Transport (Local Servers)

```nix
{
  hosting.hermes-agent.mcpServers = {
    filesystem = {
      command = "npx";
      args = ["-y" "@modelcontextprotocol/server-filesystem" "/data/workspace"];
    };
    github = {
      command = "npx";
      args = ["-y" "@modelcontextprotocol/server-github"];
      env = { GITHUB_TOKEN = "\${GITHUB_PERSONAL_ACCESS_TOKEN}"; };
      tools = {
        include = ["list_issues" "create_issue" "search_code"];
        resources = false;
        prompts = false;
      };
    };
    time = {
      command = "uvx";
      args = ["mcp-server-time"];
    };
  };
}
```

> **Important**: Environment variable references like `\${GITHUB_TOKEN}` are resolved from the agent's `.env` file at runtime. Never put raw tokens in Nix configuration — use sops-nix secrets and reference them via env vars.

#### HTTP Transport (Remote Servers)

```nix
{
  hosting.hermes-agent.mcpServers = {
    "remote-api" = {
      url = "https://mcp.example.com/v1/mcp";
      headers = { Authorization = "Bearer \${MCP_API_KEY}"; };
      timeout = 180;
    };
  };
}
```

#### OAuth Authentication

```nix
{
  hosting.hermes-agent.mcpServers."my-oauth-server" = {
    url = "https://mcp.example.com/mcp";
    auth = "oauth";
  };
}
```

Hermes implements the full OAuth 2.1 PKCE flow. Tokens are persisted in `$HERMES_HOME/mcp-tokens/<server-name>.json`.

#### Tool Filtering

```nix
{
  hosting.hermes-agent.mcpServers.github = {
    command = "npx";
    args = ["-y" "@modelcontextprotocol/server-github"];
    env = { GITHUB_TOKEN = "\${GITHUB_TOKEN}"; };
    # Only expose specific tools
    tools = {
      include = ["list_issues" "create_issue" "update_issue" "search_code"];
      resources = false;  # Disable resource access
      prompts = false;    # Disable prompt templates
    };
  };
}
```

#### Server-Initiated Sampling

Some MCP servers can request LLM completions from the agent:

```nix
{
  hosting.hermes-agent.mcpServers.analysis = {
    command = "npx";
    args = ["-y" "analysis-server"];
    sampling = {
      enabled = true;
      model = "google/gemini-3-flash";
      maxTokensCap = 4096;
      timeout = 30;
      maxRpm = 10;
    };
  };
}
```

#### Reloading MCP Servers

After changing MCP configuration, you can reload servers without restarting the entire agent:

```
/reload-mcp
```

Or restart just the gateway:

```bash
systemctl restart hermes-agent
```

### Documents

Files to install into the agent's working directory. Hermes reads specific files by convention.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `documents` | `attrsOf (str or path)` | `{}` | Workspace files for the agent |

```nix
{
  hosting.hermes-agent.documents = {
    "USER.md" = ''# About Me
    I'm a software engineer who prefers Rust and Nix.
    I maintain a homelab with various self-hosted services.'';
    "project-context.md" = ./documents/project-context.md;
  };
}
```

> **Note**: The agent's primary identity file (SOUL.md) lives at `$HERMES_HOME/SOUL.md` in the state directory. It is separate from the documents option. Set it by managing the file directly at `${hosting.hermes-agent.stateDir}/.hermes/SOUL.md`.

### Custom Settings

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `settings` | `attrs` | `{}` | Additional settings deep-merged into config.yaml |

These correspond 1:1 with YAML keys in `~/.hermes/config.yaml`. Nix-declared keys always win, but user-added keys are preserved across rebuilds.

```nix
{
  hosting.hermes-agent.settings = {
    display = {
      compact = false;
      personality = "kawaii";
    };
    memory = {
      memory_enabled = true;
      user_profile_enabled = true;
    };
    terminal = {
      backend = "local";
      timeout = 180;
    };
    compression = {
      enabled = true;
      threshold = 0.85;
      summary_model = "google/gemini-3-flash-preview";
    };
    plugins.enabled = ["hermes-lcm"];
    toolsets = ["all"];
  };
}
```

For the authoritative list of config keys:

```bash
nix build .#configKeys && cat result
```

### Extra Dependencies

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `extraDependencyGroups` | `list of str` | `[]` | Python dependency groups from pyproject.toml |
| `extraPackages` | `list of package` | `[]` | System packages to add to PATH |

```nix
{
  hosting.hermes-agent = {
    # Enable messaging platforms
    extraDependencyGroups = ["messaging"];
    # Add system tools
    extraPackages = [pkgs.pandoc pkgs.imagemagick pkgs.jq];
  };
}
```

**Available dependency groups:**

| Group | What it enables |
|-------|-----------------|
| `messaging` | Discord, Telegram, Slack |
| `matrix` | Matrix/Element (mautrix with encryption) |
| `voice` | Local speech-to-text (faster-whisper) |
| `edge-tts` | Edge TTS provider |
| `tts-premium` | ElevenLabs TTS |
| `anthropic` | Native Anthropic SDK |
| `bedrock` | AWS Bedrock (boto3) |
| `hindsight` | Hindsight memory provider |
| `honcho` | Honcho memory provider |
| `exa` | Exa web search |
| `firecrawl` | Firecrawl web search |
| `fal` | FAL image generation |

### Container

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `container.backend` | `"docker" or "podman"` | `"docker"` | Container runtime backend |
| `container.image` | `str` | `"ubuntu:24.04"` | OCI container image |
| `container.extraVolumes` | `list of str` | `[]` | Extra volume mounts (host:container:mode) |
| `container.extraOptions` | `list of str` | `[]` | Extra docker/podman create arguments |
| `container.autoEnableRuntime` | `bool` | `true` | Auto-enable virtualisation.docker or virtualisation.podman |

```nix
{
  hosting.hermes-agent.container = {
    backend = "docker";
    extraVolumes = ["/data/projects:/workspace:rw"];
    extraOptions = ["--gpus" "all"];
    # Runtime (docker/podman) is auto-enabled — set to false if managing separately
    autoEnableRuntime = true;
  };
}
```

### Host Users

Interactive users who get:

- Added to the `hermes` group for runtime file access
- A `~/.hermes` symlink to the service state directory (so `hermes chat`, `hermes setup --portal`, etc. share state with the container)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `hostUsers` | `list of str` | `[]` | Interactive users with state access |

______________________________________________________________________

## Secrets Architecture

This module integrates with **sops-nix** for secret management. Here's how secrets flow through the system:

```
sops-encrypted file          NixOS build                   Runtime
─────────────────    ────────────────────────    ───────────────────
secrets/hermes.yml    secrets."hermes/env"       /var/lib/hermes/.env
                     ──── decrypts to ────▶     ├─ OPENROUTER_API_KEY
  hermes/env: |                                ├─ ANTHROPIC_API_KEY
    KEY=value                                   ├─ TELEGRAM_BOT_TOKEN
    KEY=value                                   └─ ...
                     services.hermes-agent
                       .environmentFiles        systemd service reads
                       = [decrypted path]       .env on every restart
```

### Default Secret

A default `hermes/env` sops secret is automatically wired when the module is enabled. Place API keys in your system's sops file:

```yaml
hermes/env: |
  OPENROUTER_API_KEY=sk-or-your-key-here
  ANTHROPIC_API_KEY=sk-ant-your-key-here
```

### Additional Secrets

For platform tokens or other sensitive values, define additional secrets:

```nix
{
  hosting.hermes-agent.secrets = {
    "hermes/github" = {
      sopsFile = ./secrets/github-token.yml;
    };
    "hermes/slack" = {};
  };
}
```

Each secret is decrypted and its path passed to `services.hermes-agent.environmentFiles`. The agent reads all environment files on startup.

______________________________________________________________________

## Agent Identity: SOUL.md

Hermes' persona and behavior are defined by a `SOUL.md` file in the state directory. By default this is:

```
/var/lib/hermes/.hermes/SOUL.md
```

Manage it by writing to that path directly (e.g., via a systemd tmpfiles rule, a post-build script, or manually):

```bash
# Example: inject a personality
cat > /var/lib/hermes/.hermes/SOUL.md << 'EOF'
You are a helpful homelab assistant. You manage NixOS configurations,
monitor system health, and assist with infrastructure tasks.
EOF
```

______________________________________________________________________

## Verification & Troubleshooting

### Check service status

```bash
systemctl status hermes-agent
```

### Watch logs

```bash
journalctl -u hermes-agent -f
```

### Test the CLI

If `addToSystemPackages = true` (default):

```bash
hermes version
hermes config    # Shows the generated config
hermes chat
```

### Reload MCP servers

```
/reload-mcp
```

### Restart the gateway

```bash
systemctl restart hermes-agent
```

### Common issues

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Service fails to start | Missing API keys | Check your sops secrets contain at least one LLM provider key |
| MCP server not connecting | Runtime not on PATH | Ensure `npx` or `uvx` is available via extraPackages |
| CLI not found | addToSystemPackages = false | Run `hermes` via the systemd service's full path |
| LSP not working | Server binary not found | Set `lsp.installStrategy = "auto"` or install manually |
| Permission denied on state dir | Wrong ownership | Check `systemctl status hermes-agent` for user/group info |

______________________________________________________________________

## Full Configuration Example

```nix
{
  hosting.hermes-agent = {
    enable = true;

    # ── Model ──────────────────────────────────────
    model = "anthropic/claude-sonnet-4";
    provider.baseUrl = "https://openrouter.ai/api/v1";

    # ── Container ──────────────────────────────────
    container = {
      backend = "docker";
      extraVolumes = ["/data/projects:/workspace:rw"];
    };

    # ── Secrets ────────────────────────────────────
    # API keys stored in sops-encrypted hermes/env
    # Additional secrets:
    secrets = {
      "hermes/github" = {};
    };

    # ── Non-secret environment ─────────────────────
    environment = {
      HERMES_LOG_LEVEL = "info";
    };

    # ── LSP ────────────────────────────────────────
    lsp = {
      enable = true;
      installStrategy = "auto";
      servers = {
        pyright = {
          initializationOptions = {
            python.analysis.typeCheckingMode = "basic";
          };
        };
        rust-analyzer = {
          disable = true;
        };
      };
    };

    # ── MCP Servers ────────────────────────────────
    mcpServers = {
      filesystem = {
        command = "npx";
        args = ["-y" "@modelcontextprotocol/server-filesystem" "/var/lib/hermes/workspace"];
      };
    };

    # ── Dependencies ───────────────────────────────
    extraDependencyGroups = ["messaging"];
    extraPackages = [
      pkgs.pandoc
      pkgs.ripgrep
    ];

    # ── Agent personality ──────────────────────────
    settings = {
      display.personality = "kawaii";
      memory.memory_enabled = true;
      terminal.backend = "local";
    };

    # ── Documents ──────────────────────────────────
    documents."USER.md" = ''
      # About the User
      I maintain this NixOS homelab. Help me manage services,
      monitor system health, and automate infrastructure tasks.
    '';
  };
}
```

______________________________________________________________________

## Migration from Native Mode

This module now uses **OCI container mode** by default. If you were previously using native mode or need to switch back:

| Feature | Container (this module) | Native |
|---------|------------------------|--------|
| Security | Docker/Podman isolation | NoNewPrivileges, ProtectSystem=strict |
| Agent self-install | Yes — apt, pip, npm | No — Nix-managed PATH only |
| Config surface | Same | Same |
| Performance | Container overhead | Lower overhead |
| Use case | Mutable, self-improving | Declarative, reproducible |

To switch back to native mode, override the upstream option directly:

```nix
{
  services.hermes-agent.container.enable = false;
}
```

______________________________________________________________________

## Upstream Module Options

This module wraps `services.hermes-agent` from the upstream hermes-agent flake. For options not exposed through `hosting.hermes-agent`, configure `services.hermes-agent` directly:

```nix
{
  services.hermes-agent = {
    # Custom package override
    package = inputs.hermes-agent.packages.${pkgs.system}.default.override {
      extraPythonPackages = [...];
    };
    # Container config
    container = {
      extraVolumes = ["/data:/data:rw"];
      hostUsers = ["your-username"];
    };
    # Plugin configuration
    extraPlugins = [(pkgs.fetchFromGitHub {...})];
    extraPythonPackages = [(pkgs.python312Packages.buildPythonPackage {...})];
  };
}
```
