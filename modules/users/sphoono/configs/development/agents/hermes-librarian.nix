/**
  The Librarian: a Hermes bot profile that maintains the Molecular Zettelkasten
  in `Research/` of the Obsidian vault. The rules it follows live in the vault,
  in `Research/_System.md`; the soul only points there.

  Its filesystem tool is rooted at `Research/`, so "never touch anything
  outside it" is enforced by the tool and not only by the prompt.
*/
_: {
  den.aspects.sphoono.development.hermes.librarian.homeManager =
    {
      config,
      pkgs,
      ...
    }:
    let
      research = "${config.home.homeDirectory}/Shared/Vault/Research";
      obsidianSkills = pkgs.agent-skills.github.obsidianmd.obsidian-skills;
    in
    {
      services.hermes-agent.profiles.librarian = {
        description = "Maintains the Molecular Zettelkasten in Research/: files inbox captures, checks the rules and drafts promotions.";

        soul = ''
          ${builtins.readFile ../../../assets/documents/agent-roles/librarian.md}

          ${builtins.readFile ../../../assets/documents/agents/hermes-librarian.md}
        '';

        # Plain file editing only. obsidian-cli is left out: it needs a running
        # Obsidian GUI, which a bot does not have.
        skills = {
          inherit (obsidianSkills) obsidian-bases obsidian-markdown;
        };

        mcpServers.vault = {
          command = "${pkgs.mcp-server-filesystem}/bin/mcp-server-filesystem";
          args = [ research ];
        };

        # Profile config is separate from the default profile's, so the
        # provider is declared again. The model is picked at runtime, as for
        # the default profile.
        settings.providers."9router" = {
          api = config.development.ninerouter.url;
          key_env = "NINEROUTER_API_KEY";
          transport = "chat_completions";
        };

        environmentFiles = [ config.sops.templates."hermes/env".path ];

        # Dormant: it only fires while a Hermes gateway runs, and the hermes
        # aspect has no gateway mode yet. Until then, run the loop by hand.
        cron.jobs.pass = {
          schedule = "0 */2 * * *";
          prompt = "Read Research/_System.md, then run one pass of the loop.";
        };
      };
    };
}
