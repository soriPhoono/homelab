{ inputs, ... }:
{
  flake-file.inputs = {
    fish-bass = {
      url = "github:edc/bass/v1.0";
      flake = false;
    };
    fish-sponge = {
      url = "github:meaningful-ooo/sponge/1.1.0";
      flake = false;
    };
    fish-done = {
      url = "github:franciscolourenco/done/1.21.1";
      flake = false;
    };
    fish-pisces = {
      url = "github:laughedelic/pisces/v0.7.0";
      flake = false;
    };
  };

  den.aspects.sphoono = {
    homeManager = { pkgs, ... }: {
      programs.fish = {
        enable = true;
        plugins = with pkgs; [
          {
            name = "bass";
            src = stdenv.mkDerivation {
              pname = "fish-bass";
              version = "1.0-7-20-18";

              src = inputs.fish-bass;

              buildPhase = ''
                substituteInPlace functions/bass.fish \
                  --replace-fail "python " "${python3}/bin/python3 "
                substituteInPlace functions/__bass.py \
                  --replace-fail "env_reader = \"python -c " "env_reader = \"${python3}/bin/python3 -c "
              '';

              installPhase = ''
                mkdir -p $out
                cp -r . $out
              '';
            };
          }
          {
            name = "sponge";
            src = inputs.fish-sponge;
          }
          {
            name = "done";
            src = inputs.fish-done;
          }
          {
            name = "pisces";
            src = inputs.fish-pisces;
          }
        ];
        interactiveShellInit = ''
          set fish_greeting

          set -U __done_min_cmd_duration 2500
        '';
      };
    };
  };
}
