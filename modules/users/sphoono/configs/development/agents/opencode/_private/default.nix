{
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./plugins/honcho.nix

    ./providers/9router.nix

    ./skills.nix
    ./mcp.nix
  ];

  programs.opencode = {
    enable = true;
    package =
      let
        agent = pkgs.opencode;
      in
      pkgs.symlinkJoin {
        inherit (agent) pname version meta;
        name = "${agent.pname}-wrapped-${agent.version}";

        paths = [ agent ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          for bin in $out/bin/*; do
            if [ -f "$bin" ] && [ -x "$bin" ]; then
              wrapProgram "$bin" \
                --prefix PATH : ${
                  lib.makeBinPath [
                    pkgs.nodejs
                    pkgs.python3
                  ]
                } \
                --run 'export OPENCODE_DISABLE_CLAUDE_CODE=1'
            fi
          done
        '';
      };
    context = ''
      ${builtins.readFile ../../assets/USER.md}

      ${builtins.readFile ../assets/AGENTS.md}
    '';
    agents = {
      coding-agent = ../../../assets/documents/agent-roles/coding.md;
      devops = ../../../assets/documents/agent-roles/nix-infrastructure.md;
    };
  };
}
