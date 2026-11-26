{ den, ... }: {
  den.aspects.sphoono.development.includes = [
    # Tools
    den.aspects.sphoono.development.tools.herdr
    den.aspects.sphoono.development.editors.nvim
    den.aspects.sphoono.development.agents.claude-code
    den.aspects.sphoono.development.agents.opencode
    den.aspects.sphoono.development.agents.hermes
    den.aspects.sphoono.development.tools.gh
  ];

  den.aspects.sphoono.development.desktop.includes = [
    den.aspects.sphoono.development.editors.obsidian
    den.aspects.sphoono.development.agents.hermes.desktop
    den.aspects.sphoono.development.editors.zed
  ];
}
