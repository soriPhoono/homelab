let
  key = lhs: desc: cmd: {
    key = "<leader>s${lhs}";
    mode = "n";
    inherit desc;
    action = "<cmd>Lspsaga ${cmd}<CR>";
  };
in
{
  programs.nvf.settings.vim = {
    lsp.lspsaga.enable = true;

    # Keep the sign-column bulb only; the end-of-line one duplicates it.
    lsp.lspsaga.setupOpts.lightbulb.virtual_text = false;

    # nvf maps nothing for lspsaga; these sit beside the built-in <leader>l LSP maps.
    keymaps = [
      (key "f" "Finder (references, implementations)" "finder")
      (key "p" "Peek definition" "peek_definition")
      (key "t" "Peek type definition" "peek_type_definition")
      (key "o" "Outline" "outline")
      (key "d" "Line diagnostics" "show_line_diagnostics")
    ];

    binds.whichKey.register."<leader>s" = "+Saga";
  };
}
