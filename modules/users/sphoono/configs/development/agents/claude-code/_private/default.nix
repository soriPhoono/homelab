{ inputs }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  mem0Key = config.sops.secrets."api/mem0-api-key".path;

  # Claude Code requires `name` and `description` frontmatter on agents; the
  # shared role files carry none, since opencode takes them bare.
  role = name: description: file: ''
    ---
    name: ${name}
    description: ${description}
    ---

    ${builtins.readFile file}
  '';
in
{
  imports = [
    (import ./plugins/mem0.nix { inherit inputs; })

    ./mcp.nix
  ];

  programs.claude-code = {
    enable = true;
    package =
      let
        agent = pkgs.claude-code;
      in
      pkgs.symlinkJoin {
        inherit (agent) pname version meta;
        name = "${agent.pname}-wrapped-${agent.version}";

        paths = [ agent ];
        buildInputs = [ pkgs.makeWrapper ];
        # Skills ship node and python helper scripts, and the mem0 plugin's
        # hooks and MCP server run on python3. The mem0 key is read from its
        # sops secret at launch, so it never enters the store; its PostHog
        # telemetry is switched off.
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
                --set MEM0_TELEMETRY false \
                --run '[ -r "${mem0Key}" ] && export MEM0_API_KEY="$(< "${mem0Key}")"'
            fi
          done
        '';
      };
    context = ''
      ${builtins.readFile ../../assets/USER.md}

      ${builtins.readFile ../assets/CLAUDE.md}
    '';
    agents = {
      coding-agent =
        role "coding-agent"
          "General software engineering: implement, debug and review code with small, verified changes."
          ../../assets/agent-roles/coding.md;
      devops =
        role "devops"
          "NixOS, Home Manager and infrastructure-as-code changes, following the repository's AGENTS.md and verification gates."
          ../../assets/agent-roles/nix-infrastructure.md;
    };
    skills = import ../../_private/skills.nix { inherit inputs lib pkgs; };
  };
}
