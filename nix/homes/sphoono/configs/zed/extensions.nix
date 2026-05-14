{
  programs.zed-editor.extensions = [
    # Configuration
    "editorconfig" # EditorConfig support for consistent coding styles
    "desktop" # Desktop file syntax highlighting and LSP
    "log" # Log file syntax highlighting and LSP
    "makefile" # Makefile syntax highlighting and LSP
    "csv" # CSV syntax highlighting and LSP
    "xml" # XML syntax highlighting and LSP
    "toml" # TOML syntax highlighting and LSP

    # Desktop / System
    "fish" # Fish shell syntax highlighting and LSP
    "caddyfile" # Caddy web server syntax highlighting and LSP
    "dockerfile" # Dockerfile syntax highlighting and LSP
    "docker-compose" # Docker Compose YAML support

    # Mobile / Cross platform
    "dart" # Dart language support (Flutter development)
    "kotlin" # Kotlin language support (Android development)

    # Web2 Development
    "ruby" # Ruby language support
    "biome" # Biome code formatter and linter (JS/TS)
    "deno" # Deno runtime (JS/TS server-side)
    "html" # HTML support
    "php" # PHP language support
    "vue" # Vue.js framework
    "tailwindcss" # Tailwind CSS framework
    "astro" # Astro web framework
    "svelte" # Svelte framework

    # Web3 / Crypto
    "solidity" # Solidity syntax highlighting and LSP

    # DevOps
    "github-actions" # GitHub Actions workflow syntax highlighting and LSP
    "terraform" # Terraform IaC syntax
    "opentofu" # OpenTofu IaC syntax
    "ansible" # Ansible playbooks
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
  ];
}
