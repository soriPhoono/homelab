{ den, ... }: {
  # Shared by the claude, opencode and codex aspects below. Declared here so
  # retiring claude does not orphan the inputs the surviving agents consume.
  flake-file.inputs = {
    mem0 = {
      url = "github:mem0ai/mem0/v2.2.1";
      flake = false;
    };
    awesome-ai-agent-skills = {
      url = "github:seb1n/awesome-ai-agent-skills/75865a5d037a4cdaa7f409a4ec14ab9b0292920b";
      flake = false;
    };
  };

  den.aspects.sphoono.development.includes = [
    # Tools
    den.aspects.sphoono.development.herdr
    den.aspects.sphoono.development.nvim
    den.aspects.sphoono.development.opencode-gateway
    den.aspects.sphoono.development.claude
    den.aspects.sphoono.development.opencode
    den.aspects.sphoono.development.codex
    den.aspects.sphoono.development.gh
  ];
}
