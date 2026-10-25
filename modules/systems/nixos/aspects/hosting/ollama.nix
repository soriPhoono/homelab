/**
  Local LLM runtime: an Ollama server for open-weight models, bound to
  loopback. Models are pulled by hand (`ollama pull`), not declared, since
  weights are state rather than configuration.
*/
{ den, ... }:
{
  den.aspects.hosting.ollama = {
    nixos = _: {
      services.ollama = {
        enable = true;
        host = "127.0.0.1";
        port = 11434;
        openFirewall = false;
        environmentVariables = {
          # Single user: one resident model, unloaded after five idle minutes
          # so the GPU is free for everything else.
          OLLAMA_MAX_LOADED_MODELS = "1";
          OLLAMA_NUM_PARALLEL = "1";
          OLLAMA_KEEP_ALIVE = "5m";
          OLLAMA_CONTEXT_LENGTH = "16384";
          OLLAMA_FLASH_ATTENTION = "1";
          OLLAMA_KV_CACHE_TYPE = "q8_0";
        };
      };
    };

    # AMD GPUs through ROCm. gfx1100 (RX 7900 XTX) is supported upstream, so
    # no `rocmOverrideGfx` is needed.
    rocm = {
      includes = [
        den.aspects.hosting.ollama
      ];
      nixos =
        { pkgs, ... }:
        {
          services.ollama.package = pkgs.ollama-rocm;
        };
    };
  };
}
