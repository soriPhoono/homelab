{ den, ... }: {
  den.aspects.sphoono.configs.development.includes = [
    # Desktop environment
    den.aspects.sphoono.configs.desktop

    # Agents
    den.aspects.sphoono.configs.claude

    # Editors
    den.aspects.sphoono.configs.vscode
  ];
}
