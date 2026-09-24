{lib, ...}:
with lib; {
  options.apps.development.agents = {
    extraPackages = mkOption {
      type = with types; listOf package;
      default = [];
      description = ''
        Extra packages to include with the development agents (global).
      '';
    };

    secrets = mkOption {
      type = with types; listOf str;
      default = [];
      description = ''
        Secrets to include with the development agents (global).
      '';
      example = [
        "api/mem0-api-key"
      ];
    };

    context = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Context to include with the development agents (global).
      '';
    };
  };

  config = mkMerge [
    {
    }
  ];
}
