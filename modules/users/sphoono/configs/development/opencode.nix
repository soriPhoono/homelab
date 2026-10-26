/**
  OpenCode, pointed at the local 9router gateway. The gateway is the same on
  every host, so the provider is declared everywhere; a model only answers
  where its backend runs (the Gemma 4 build lives on desktop-ares).
*/
_: {
  den.aspects.sphoono.development.opencode = {
    homeManager = _: {
      programs.opencode = {
        enable = true;
        settings = {
          "$schema" = "https://opencode.ai/config.json";
          provider."9router" = {
            npm = "@ai-sdk/openai-compatible";
            name = "9router";
            options = {
              baseURL = "http://127.0.0.1:20128/v1";
              # 9router needs no key on loopback; the SDK wants a non-empty one.
              apiKey = "9router";
            };
            models."desktop-ollama/gemma4:26b-a4b-it-qat" = {
              name = "Gemma 4 26B-A4B QAT (desktop-ares)";
              # Matches OLLAMA_CONTEXT_LENGTH. Output is generous because the
              # model reasons first and an exhausted budget returns nothing.
              limit = {
                context = 131072;
                output = 32768;
              };
            };
          };
        };
      };
    };
  };
}
