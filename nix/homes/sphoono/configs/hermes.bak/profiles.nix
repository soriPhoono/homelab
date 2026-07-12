{pkgs, ...}: {
  apps.development.agents.hermes.profiles = {
    # ── Office ──────────────────────────────────────────────────────────
    office = {
      enable = true;
      soulDoc = ''
        You are an office productivity specialist. Your expertise lies in
        creating, editing, and organizing business documents, spreadsheets,
        presentations, and PDFs. You work efficiently with file-based
        workflows — opening existing documents, understanding their structure,
        making targeted edits, and producing polished output.

        Always prefer to read/understand a document before modifying it.
        When creating from scratch, produce clean, professional output.
        Verify your work by reading back key sections after editing.
      '';
      mcpServers = {
        "office/pptx" = {
          command = "${pkgs.office-mcp}/bin/office-mcp-pptx";
          args = [];
        };
        "office/docx" = {
          command = "${pkgs.office-mcp}/bin/office-mcp-docx";
          args = [];
        };
        "office/xlsx" = {
          command = "${pkgs.office-mcp}/bin/office-mcp-xlsx";
          args = [];
        };
        "office/pdf" = {
          command = "${pkgs.uv}/bin/uvx";
          args = [
            "pdf-edit-mcp"
          ];
        };
      };
    };

    # ── Coder ───────────────────────────────────────────────────────────
    coder = {
      enable = true;
      soulDoc = ./CODER.md;
      mcpServers = {
        "software-dev/github" = {
          command = "${pkgs.nodejs}/bin/npx";
          args = [
            "-y"
            "@modelcontextprotocol/server-github"
          ];
          env = {
            GITHUB_PERSONAL_ACCESS_TOKEN = {
              secret = "api/GITHUB_TOKEN";
            };
          };
        };
        "software-dev/nixos" = {
          command = "${pkgs.uv}/bin/uvx";
          args = [
            "mcp-nixos"
          ];
        };
        "software-dev/database" = {
          command = "${pkgs.nodejs}/bin/npx";
          args = [
            "-y"
            "anydb-mcp"
          ];
        };
      };
    };

    # ── DevOps ──────────────────────────────────────────────────────────
    devops = {
      enable = true;
      soulDoc = ''
        You are a DevOps engineer. Your domain spans infrastructure,
        containerization, orchestration, CI/CD, monitoring, and cloud
        platforms. You work with Docker, Kubernetes, Linux systems,
        configuration management, and infrastructure-as-code.

        Always verify the current state before making changes. Prefer
        read-only operations when exploring. Apply changes incrementally
        and confirm success after each step.
      '';
      mcpServers = {
        "software-dev/github" = {
          command = "${pkgs.nodejs}/bin/npx";
          args = [
            "-y"
            "@modelcontextprotocol/server-github"
          ];
          env = {
            GITHUB_PERSONAL_ACCESS_TOKEN = {
              secret = "api/GITHUB_TOKEN";
            };
          };
        };
        "software-dev/nixos" = {
          command = "${pkgs.uv}/bin/uvx";
          args = [
            "mcp-nixos"
          ];
        };
        "devops/docker" = {
          command = "${pkgs.nodejs}/bin/npx";
          args = [
            "-y"
            "@alisaitteke/docker-mcp"
          ];
        };
        "devops/kubernetes" = {
          command = "${pkgs.nodejs}/bin/npx";
          args = [
            "-y"
            "kubernetes-mcp-server@latest"
            "--read-only"
          ];
        };
      };
    };
  };
}
