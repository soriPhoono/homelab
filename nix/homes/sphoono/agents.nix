{
  userapps.development.agents.context = {
    user = ''
      # User Workflow, Identity & Preferences: sphoono

      ## Identity & Contact
      - **Name**: soriphoono
      - **Email**: `soriphoono@gmail.com` (Primary contact for infrastructure, GitHub, and personal communication).
      - **GitHub**: `soriphoono`
      - **Bio**: Enthusiastic homelabber and infrastructure-as-code practitioner focused on declarative systems (NixOS), virtualization, and AI-assisted development.
      - **Projects**: Maintaining the "Data Fortress" homelab and exploring the intersection of AI agents and terminal-centric workflows.

      ## Shell & Terminal
      - **Primary Shell**: Fish (with Starship prompt and Fastfetch).
      - **Key Tools**:
        - **Lazygit (`lzg`)**: Interactive git management.
        - **Lazydocker (`lzd`)**: Interactive container management.
        - **Yazi**: Terminal file manager.
      - **Development**:
        - **Editors**: VSCode, Zed, Zen Browser (configured with specific extensions and policies).
        - **Agents**: Gemini-CLI (IDE integration enabled), OpenCode.

      ## Personal Command Patterns (Aliases)
      - **Git**: `gs` (status), `ga <file>` (add), `gc <msg>` (commit), `gch <branch>` (new branch), `gp` (push), `gpl` (pull).
      - **Docker**: `d` (docker), `dc` (docker-compose).
      - **Nix**: Use `nh os switch .` or `nh home switch .` for system/home updates.

      ---
      *This data provides GEMINI.md-style context provider for the current system session.*
    '';
  };
}
