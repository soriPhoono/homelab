{
  programs.nvf.settings.vim.visuals.rainbow-delimiters = {
    enable = true;
    # The plugin's :checkhealth only reports on explicitly configured options and
    # flags an empty report as an error, so the stock palette is spelled out.
    setupOpts.highlight = [
      "RainbowDelimiterRed"
      "RainbowDelimiterYellow"
      "RainbowDelimiterBlue"
      "RainbowDelimiterOrange"
      "RainbowDelimiterGreen"
      "RainbowDelimiterViolet"
      "RainbowDelimiterCyan"
    ];
  };
}
