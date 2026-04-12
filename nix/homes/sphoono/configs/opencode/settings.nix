_: {
  programs.opencode.settings = {
    model = "openrouter/google/gemini-3-flash-preview";

    # NOTE: These are the models to use at the top of the month till the usage runs out on my google cloud credit.
    # model = "openrouter/google/gemini-3-flash-preview";
    # small_model = "openrouter/free";

    provider = {
      openrouter = {
        options = {
          apiKey = "{env:OPENROUTER_API_KEY}";
        };
      };
    };
  };
}
