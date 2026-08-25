_: {
  vim.telescope = {
    enable = true;

    mappings = {
      buffers = "<leader>fb";
      findFiles = "<leader>ff";
      findProjects = "<leader>fp";
      gitBranches = "<leader>gvb";
      gitBufferCommits = "<leader>gbc";
      gitCommits = "<leader>gc";
      gitFiles = "<leader>gf";
      gitStash = "<leader>gx";
      gitStatus = "<leader>gs";
      helpTags = "<leader>fh";
      liveGrep = "<leader>fg";
      lspDefinitions = "<leader>lD";
      lspDocumentSymbols = "<leader>fls";
      lspImplementations = "<leader>li";
      lspReferences = "<leader>lr";
      lspTypeDefinitions = "<leader>lt";
      lspWorkspaceSymbols = "<leader>lw";
      resume = "<leader>fo";
      treesitter = "<leader>ft";
      open = null;
    };

    setupOpts = {
      defaults = {
        color_devicons = true;
        file_ignore_patterns = [
          ".git/"
          "node_modules/"
          "__pycache__/"
          "target/"
          "dist/"
          ".venv/"
        ];
      };
    };
  };
}
