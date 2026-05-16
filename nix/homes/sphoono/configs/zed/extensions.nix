{
  programs.zed-editor.extensions = [
    # Editor
    "editorconfig" # EditorConfig support for consistent coding styles

    # Configuration
    "env" # .env file support
    "ini" # INI file support
    "csv" # CSV syntax highlighting and LSP
    "xml" # XML syntax highlighting and LSP
    "toml" # TOML syntax highlighting and LSP
    "makefile" # Makefile syntax highlighting and LSP
    "nginx" # Nginx config syntax
    "caddyfile" # Caddy web server syntax highlighting and LSP

    # Desktop / Linux Development
    "log" # Log file syntax highlighting and LSP
    "desktop" # Desktop file syntax highlighting and LSP (freedesktop)
    "awk" # AWK scripting
    "fish" # Fish shell syntax highlighting and LSP
    "powershell" # PowerShell automation
    "neocmake" # CMake build system
    "ninja" # Ninja build system
    "meson" # Meson build system
    "strace" # System call tracer (Linux debugging)
    "openscad" # OpenSCAD 3D CAD modeller
    "hlsl" # HLSL shader language
    "haskell" # Haskell language (functional programming)
    "liquid" # Liquid templating
    "mermaid" # Mermaid diagrams

    # Mobile / Cross platform
    "dart" # Dart language support (Flutter development)
    "kotlin" # Kotlin language support (Android development)

    # Web2 Development
    "markdownlint" # Markdown linter
    "ruby" # Ruby language support
    "html" # HTML support
    "stylelint" # CSS/SCSS linter
    "tailwindcss" # Tailwind CSS framework
    "php" # PHP language support
    "deno" # Deno runtime (JS/TS server-side)
    "biome" # Biome code formatter and linter (JS/TS)
    "vue" # Vue.js framework
    "svelte" # Svelte framework
    "graphql" # GraphQL query language
    "http" # HTTP client for API testing

    # Web3 / Crypto
    "solidity" # Solidity syntax highlighting and LSP (EVM - Linea compatible)
    "cairo" # Cairo language (StarkNet)
    "move" # Move language (Sui/Aptos)
    "aptos-move" # Aptos Move language
    "sway" # Sway language (Fuel)
    "aiken" # Aiken language (Cardano)
    "cosmos" # Cosmos SDK
    "ask-starknet-mcp" # StarkNet MCP server
    "ink" # Ink! smart contracts (Polkadot)
    "authzed" # Authzed policy language
    "rego" # Rego policy language (OPA)

    # DevOps
    "github-actions" # GitHub Actions workflow syntax highlighting and LSP
    "opentofu" # OpenTofu IaC syntax
    "ansible" # Ansible playbooks
    "dockerfile" # Dockerfile syntax highlighting and LSP
    "docker-compose" # Docker Compose YAML support
    "helm" # Helm charts (K8s package manager)
    "kubernetes" # Kubernetes manifests

    # Languages
    "nix"
    "bash"
    "lua"
    "perl"
    "python"
    "css"
    "scss"
    "javascript"
    "typescript"
    "golang"
    "rust"
    "java"
    "csharp"
    "zig"
    "ocaml"
    "sql"
    "shader-ls"

    # Extra useful
    "git-firefly" # Enhanced Git integration (commits, branches, etc.)

    # Assistant / MCP Servers
    # General
    "serena-context-server" # Serena code assistant

    # Desktop
    "arch-mcp" # Arch Linux package management
    "mcp-server-godot" # Godot game engine

    # DevOps
    "mcp-server-grafana" # Grafana monitoring
    "mcp-server-gitlab" # GitLab CI/CD
    "mcp-server-buildkite" # Buildkite CI/CD
    "mcp-server-digitalocean" # DigitalOcean cloud
    "sentry-mcp" # Sentry error tracking

    # Web2 Development
    "browser-tools-context-server" # Browser developer tools
    "bun-docs-mcp" # Bun runtime docs
    "prisma-mcp" # Prisma ORM
    "libsql-context-server" # libsql database
    "postgres-context-server" # PostgreSQL database
    "mcp-server-mysql" # MySQL database
    "postman-context-server" # Postman API testing
    "shadcn-mcp" # shadcn/ui components
    "svelte-mcp" # Svelte framework
    "mcp-server-resend" # Resend email API
    "mcp-server-shopify-dev" # Shopify development
    "polar-context-server" # Polar payment processing

    # Web3 / Blockchain (Sky/MakerDAO + Linea focused)
    "ask-starknet-mcp" # StarkNet MCP server
  ];
}
