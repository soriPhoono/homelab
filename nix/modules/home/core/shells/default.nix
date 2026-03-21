{
  lib,
  config,
  ...
}: {
  imports = [
    ./fish.nix

    ./starship.nix
    ./fastfetch.nix
  ];

  options.core.shells = {
    shellAliases = lib.mkOption {
      type = with lib.types; attrsOf str;
      default = {};
      description = "Shell command aliases";
      example = {
        g = "git";
      };
    };

    sessionVariables = lib.mkOption {
      type = with lib.types; attrsOf str;
      default = {};
      description = "Environment variables to set for the user";
      example = {
        Foo = "Hello";
        Bar = "${config.core.shells.sessionVariables.Foo} World!";
      };
    };
  };

  config = {
    programs = {
      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };

      eza = {
        enable = true;

        git = true;
        icons = "auto";

        extraOptions = [
          "--group-directories-first"
        ];
      };

      btop.enable = true;
    };
  };
}
