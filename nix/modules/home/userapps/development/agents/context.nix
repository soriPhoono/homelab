{lib, ...}:
with lib; {
  options.userapps.development.agents.context = {
    system = mkOption {
      type = types.nullOr types.lines;
      default = null;
      description = "The system context in a user perspective (hardware, OS, etc.).";
    };
    user = mkOption {
      type = types.nullOr types.lines;
      default = null;
      description = "The user context (personal workflow, preferences, aliases, and identity).";
    };
  };
}
