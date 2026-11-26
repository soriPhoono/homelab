{ den, ... }: {
  den.aspects.spookyskelly.development.includes = [
    # Tools
    den.aspects.spookyskelly.development.agents.antigravity
    den.aspects.spookyskelly.development.tools.gh
  ];

  den.aspects.spookyskelly.development.desktop.includes = [
    den.aspects.spookyskelly.development.editors.obsidian
    den.aspects.spookyskelly.development.agents.antigravity.desktop
    den.aspects.spookyskelly.development.editors.zed
  ];
}
