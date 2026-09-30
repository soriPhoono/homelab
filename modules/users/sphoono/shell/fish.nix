{
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

              src = fetchFromGitHub {
                owner = "edc";
                repo = "bass";
                rev = "v1.0";
                hash = "sha256-XpB8u2CcX7jkd+FT3AYJtGwBtmNcLXtfMyT/z7gfyQw=";
              };

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
            src = fetchFromGitHub {
              owner = "meaningful-ooo";
              repo = "sponge";
              rev = "v1.1.0";
              hash = "sha256-MdcZUDRtNJdiyo2l9o5ma7nAX84xEJbGFhAVhK+Zm1w=";
            };
          }
          {
            name = "done";
            src = fetchFromGitHub {
              owner = "franciscolourenco";
              repo = "done";
              rev = "1.21.1";
              hash = "sha256-GZ1ZpcaEfbcex6XvxOFJDJqoD9C5out0W4bkkn768r0=";
            };
          }
          {
            name = "pisces";
            src = fetchFromGitHub {
              owner = "laughedelic";
              repo = "pisces";
              rev = "v0.7.0";
              hash = "sha256-Oou2IeNNAqR00ZT3bss/DbhrJjGeMsn9dBBYhgdafBw=";
            };
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
