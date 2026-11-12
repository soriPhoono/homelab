{ config, ... }:
let
  home = config.home.homeDirectory;

  key = lhs: desc: cmd: {
    key = "<leader>o${lhs}";
    mode = "n";
    inherit desc;
    action = "<cmd>Obsidian ${cmd}<CR>";
  };
in
{
  programs.nvf.settings.vim = {
    notes.obsidian = {
      enable = true;
      setupOpts = {
        workspaces = [
          {
            name = "vault";
            path = "${home}/Shared/Vault";
          }
          {
            # The agent wiki is a vault of its own, one wiki per domain.
            name = "agent-wiki";
            path = "${home}/Shared/AgentWiki";
          }
        ];
        # Follows the layout Obsidian's daily-notes plugin uses in the vault.
        daily_notes = {
          folder = "01 Daily";
          date_format = "YYYY/MM-MMMM/YYYY-MM-DD-dddd";
          workdays_only = false;
        };
        # The vault's own templates use Templater, which obsidian.nvim cannot
        # run; this folder is for the plain {{date}}/{{title}} templates.
        templates.folder = "06 Templates";
      };
    };

    keymaps = [
      (key "n" "New note" "new")
      (key "o" "Open in Obsidian" "open")
      (key "f" "Find note" "quick_switch")
      (key "s" "Search notes" "search")
      (key "t" "Today's note" "today")
      (key "d" "Daily notes" "dailies")
      (key "b" "Backlinks" "backlinks")
      (key "l" "Links in note" "links")
      (key "g" "Tags" "tags")
      (key "T" "Insert template" "template")
      (key "c" "Table of contents" "toc")
      (key "w" "Switch workspace" "workspace")
      (key "r" "Rename note" "rename")
      (key "p" "Paste image" "paste_img")
    ];

    binds.whichKey.register."<leader>o" = "+Obsidian";
  };
}
