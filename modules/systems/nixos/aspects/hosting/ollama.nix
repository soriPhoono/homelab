/**
  Local LLM runtime: an Ollama container for open-weight models, published to
  the tailnet through docktail as `<host>-ollama`. Models are pulled by hand
  (`docker exec ollama ollama pull`), not declared, since weights are state
  rather than configuration.

  The base aspect runs on the CPU. Include a sub-aspect to accelerate it:
  `rocm` for AMD GPUs or `nvidia` for NVIDIA GPUs.
*/
{ den, ... }:
{
  den.aspects.hosting.ollama = {
    includes = [
      den.aspects.hosting.microserver
    ];

    nixos =
      { config, ... }:
      {
        virtualisation.oci-containers.containers.ollama = {
          image = "ollama/ollama:0.40.14";
          environment = {
            # Single user: one resident model, unloaded after five idle minutes
            # so the GPU is free for everything else.
            OLLAMA_MAX_LOADED_MODELS = "1";
            OLLAMA_NUM_PARALLEL = "1";
            OLLAMA_KEEP_ALIVE = "5m";
            # Ollama truncates a prompt to half the context, so this is a
            # 64k-token prompt budget. Measured on gemma4:26b-a4b-it-qat: 5.6
            # GiB of the 24 GiB card stays free. The Q4_K_M build at 262144
            # starved the compositor, so keep this modest.
            OLLAMA_CONTEXT_LENGTH = "131072";
            OLLAMA_FLASH_ATTENTION = "1";
            OLLAMA_KV_CACHE_TYPE = "q8_0";
            # Listen on all container interfaces so docktail can proxy to it.
            OLLAMA_HOST = "0.0.0.0:11434";
          };
          volumes = [
            "ollama:/root/.ollama"
          ];
          networks = [ "tailscale" ];
          labels = import ./_private/docktail-labels.nix {
            inherit (config.networking) hostName;
            serviceName = "ollama";
            containerPort = 11434;
          };
        };
      };

    # NVIDIA GPUs through CUDA, using the CDI devices the container toolkit
    # generates.
    nvidia = {
      includes = [
        den.aspects.core.hardware.gpu.nvidia.container-toolkit
        den.aspects.hosting.ollama
      ];

      nixos = _: {
        virtualisation.oci-containers.containers.ollama.extraOptions = [
          "--device=nvidia.com/gpu=all"
        ];
      };
    };

    # AMD GPUs through ROCm. gfx1100 (RX 7900 XTX) is supported upstream, so
    # no HSA_OVERRIDE_GFX_VERSION is needed.
    rocm = {
      includes = [
        den.aspects.hosting.ollama
      ];

      nixos =
        { lib, ... }:
        {
          virtualisation.oci-containers.containers.ollama = {
            image = lib.mkForce "ollama/ollama:0.40.14-rocm";
            # Only the dGPU (pci-0000:03:00.0); renderD128 is the iGPU.
            extraOptions = [
              "--device=/dev/kfd:/dev/kfd"
              "--device=/dev/dri/renderD129:/dev/dri/renderD129"
            ];
          };
        };
    };
  };
}
