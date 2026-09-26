# --- flake-parts/treefmt.nix
{ inputs, ... }:
{
  imports = with inputs; [ treefmt-nix.flakeModule ];

  perSystem =
    { pkgs, ... }:
    {
      treefmt = {
        # treefmt is a formatting tool that saves you time: it provides
        # developers with a universal way to trigger all formatters needed for the
        # project in one place.
        # For more information refer to
        #
        # - https://numtide.github.io/treefmt/
        # - https://github.com/numtide/treefmt-nix
        package = pkgs.treefmt;
        flakeCheck = true;
        flakeFormatter = true;
        projectRootFile = "flake.nix";

        settings = {
          global.excludes = [
            "*.age" # Age encrypted files
            "LICENSE.md"
          ];
          shellcheck.includes = [
            "*.sh"
            ".envrc"
          ];
          prettier.editorconfig = true;
        };

        programs = {
          deadnix.enable = true; # Find and remove unused code in .nix source files
          statix.enable = true; # Lints and suggestions for the nix programming language
          nixfmt.enable = true; # An opinionated formatter for Nix

          prettier.enable = true; # Opinionated formatter; owns all other code besides nix files
        };
      };
    };
}
