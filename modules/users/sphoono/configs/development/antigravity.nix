{ den, inputs, ... }:
{
  # Antigravity CLI (agy) does outside research for Claude Code and writes it
  # into the shared agent wiki. Login is imperative: run `agy` once per host.
  den.aspects.sphoono.development = {
    includes = [ (den.batteries.unfree [ "antigravity-cli" ]) ];
    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        home = config.home.homeDirectory;
        wiki = "${home}/Shared/AgentWiki";
        obsidianSkills = pkgs.agent-skills.github.kepano.obsidian-skills;
        mem0Plugin = "${inputs.mem0}/integrations/antigravity-plugin";
        notionTool = name: "mcp(notion/notion-${name})";
        # Reading the project's notes and tasks. get-tool-access is required
        # before searching, and the next-steps tools are called when the
        # server says so; print mode would deny them and end the run.
        notionReads = [
          "search"
          "ai-search"
          "fetch"
          "query-data-sources"
          "query-multiple-data-sources"
          "get-comments"
          "get-tool-access"
          "check-mcp-next-steps"
          "show-advanced-analysis-next-steps"
        ];
        # Everything that creates, changes, uploads, downloads or drives
        # Notion agents. Denied explicitly so read-only also holds in the
        # interactive TUI, where an unlisted tool would only prompt.
        notionWrites = [
          "create-pages"
          "update-page"
          "duplicate-page"
          "move-pages"
          "create-comment"
          "create-database"
          "update-data-source"
          "create-view"
          "update-view"
          "create-folder"
          "update-folder"
          "create-file-upload"
          "create-attachment"
          "download-attachment"
          "upload-skill"
          "download-skill"
          "convert-page-to-skill"
          "spawn-session"
          "send-message-to-session"
          "stop-session"
        ];
        # agy 1.2.9 discovers global skills and rules under ~/.gemini/config/
        # only. The home-manager module's `skills` and `context` options
        # write to ~/.gemini/antigravity-cli/skills and ~/.gemini/*.md, which
        # agy never reads, so both are placed here directly.
        skills = {
          inherit (obsidianSkills) obsidian-markdown defuddle;
          # mem0's own search skill. Its remember/pause/resume skills describe
          # the capture hooks, which are not installed.
          mem0-search = "${mem0Plugin}/skills/search";
          # Research protocol: wiki upkeep, requests from Claude, and plans
          # handed back to Claude.
          llm-wiki = ../../assets/skills/llm-wiki;
          research-intake = ../../assets/skills/research-intake;
          claude-handoff = ../../assets/skills/claude-handoff;
        };
      in
      {
        home.sessionVariables.AGENT_WIKI = wiki;

        # Implementation plans handed to Claude's plan-watch loop are work
        # items, not project history; their outcome lands as commits.
        programs.git.ignores = [ ".agents/plans/" ];

        programs.antigravity-cli = {
          enable = true;
          settings = {
            # What agy saved during the interactive login, declared because
            # its own writes to this file are replaced on every switch (see
            # below).
            model = "Gemini 3.8 Flash (High)";
            trustedWorkspaces = [ "${home}/Projects/homelab" ];
            toolPermission = "proceed-in-sandbox";
            # Launched from Claude Code, every sandboxed command fails with
            # "connecting to sandbox server: ... connection reset by peer"
            # and agy retries it unsandboxed, which print mode denies. Shell
            # access is limited by the read-only command allow-list instead.
            enableTerminalSandbox = false;
          };
          # Research runs headless (`agy -p`), where any tool needing approval
          # is denied, so everything research needs is allowed explicitly.
          # Targets are path prefixes matched against the resolved path
          # (skills resolve into /nix/store); a `*` inside a path does not
          # match.
          permissions = {
            allow = [
              "read_file(/nix/store)"
              "read_file(${home}/.gemini)"
              "read_file(${home}/Projects)"
              "read_url(*)"
              # Read-only shell commands; any other command is denied, which
              # ends a print-mode run.
              "command(ls)"
              "command(cat)"
              "command(head)"
              "command(tail)"
              "command(wc)"
              "command(grep)"
              # mem0 is read-only context; its server exposes no write tool.
              "mcp(mem0/search_memories)"
              # Research only writes the wiki and the root plan inbox.
              "write_file(${wiki})"
              "write_file(${home}/Projects/.agents/plans)"
            ]
            ++ map notionTool notionReads;
            # Never version control, the nix store or secrets.
            deny = [
              "command(git)"
              "command(nix)"
              "command(nh)"
              "command(nixos-rebuild)"
              "command(home-manager)"
              "command(sops)"
              "command(sudo)"
            ]
            # Claude Code is Notion's only writer.
            ++ map notionTool notionWrites;
          };
          # Only the MCP server from mem0's antigravity plugin, without its
          # capture hooks: agy reads Claude's memories for the repository it
          # runs in (the pool is keyed by the git remote) and never writes.
          # The API key is imperative: ~/.mem0/antigravity-plugin/api-key.
          mcpServers.mem0 = {
            command = lib.getExe pkgs.python3;
            args = [ "${mem0Plugin}/core/mcp_server.py" ];
            env = {
              # Without the hooks nothing sets the harness, and the server
              # would fall back to ~/.mem0/mem0-plugin.
              MEM0_PLUGIN_DATA_DIR = "${home}/.mem0/antigravity-plugin";
              # Usage events go to PostHog linked to the account email.
              MEM0_TELEMETRY = "false";
            };
          };
          # Notion's hosted MCP, so plans are written against the project's
          # current notes and tasks. OAuth is imperative: run `agy` once per
          # host. agy reads Notion only; Claude Code is its only writer.
          mcpServers.notion.serverUrl = "https://mcp.notion.com/mcp";
        };

        home.file = {
          # agy replaces this link with a regular file whenever it saves a
          # setting (the model picked at login, a trusted workspace) and on
          # its first launch while the file is a link. Without force, the
          # next switch backs it up to settings.json.hm-backup and the one
          # after fails because that backup already exists.
          ".gemini/antigravity-cli/settings.json".force = true;
          # agy creates an empty regular file here on its first run.
          ".gemini/config/mcp_config.json".force = true;

          ".gemini/config/rules/sphoono.md".text = ''
            ---
            trigger: always_on
            ---

            ${builtins.readFile ../../assets/documents/user.md}

            ${builtins.readFile ../../assets/documents/antigravity/AGENTS.md}
          '';
        }
        // builtins.listToAttrs (
          map (name: {
            name = ".gemini/config/skills/${name}";
            value = {
              source = skills.${name};
              recursive = true;
            };
          }) (builtins.attrNames skills)
        );
      };
  };
}
