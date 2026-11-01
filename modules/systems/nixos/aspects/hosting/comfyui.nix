/**
  ComfyUI diffusion UI in a container, bound to loopback. The service is
  never started at boot: start it by hand with
  `sudo systemctl start docker-comfyui` so the GPU stays free for Ollama and
  the compositor. Models and outputs live in /var/lib/comfyui as state.
*/
{ den, ... }:
{
  den.aspects.hosting.comfyui = {
    includes = [
      den.aspects.hosting.docker
    ];

    nixos =
      { lib, ... }:
      let
        stateDirectory = "/var/lib/comfyui";
      in
      {
        # The container runs as uid 1000 and keeps everything in /data.
        # ComfyUI lists custom_nodes at startup without creating it, so the
        # state layout has to exist before the first run.
        systemd.tmpfiles.rules = map (dir: "d ${stateDirectory}${dir} 0755 1000 1000 -") [
          ""
          "/custom_nodes"
          "/models"
          "/input"
          "/output"
          "/user"
        ];

        virtualisation.oci-containers.containers.comfyui = {
          image = "ghcr.io/soriphoono/comfyui-rocm:0.43.2-rocm10.1.0";
          ports = [ "127.0.0.1:8188:8188" ];
          volumes = [ "${stateDirectory}:/data:rw" ];
          # Cap RAM below the host's total so a runaway load OOM-kills the
          # container, not the desktop. The cap sits above the ~15-20 GB the
          # staged MiniMax H3 models need.
          extraOptions = [
            "--user=1000:1000"
            "--memory=20g"
            "--memory-swap=20g"
          ];

          # Unload models after each run and keep 4 GB of VRAM free for the
          # compositor and Ollama. The image entrypoint is main.py, so these
          # are appended to it.
          cmd = [
            "--disable-smart-memory"
            "--reserve-vram"
            "4"
          ];
        };

        # On demand only; see the header.
        systemd.services.docker-comfyui.wantedBy = lib.mkForce [ ];
      };

    # AMD GPUs through ROCm. gfx1100 (RX 7900 XTX) is supported upstream.
    rocm = {
      includes = [
        den.aspects.hosting.comfyui
      ];

      nixos =
        { lib, config, ... }:
        let
          cfg = config.hosting.comfyui;
        in
        {
          options.hosting.comfyui.renderDevice = lib.mkOption {
            type = lib.types.str;
            example = "/dev/dri/renderD129";
            description = ''
              Render node of the AMD GPU passed to the container, next to
              /dev/kfd. Pick the dGPU explicitly: on hosts with an iGPU the
              render nodes are not ordered by capability.
            '';
          };

          config.virtualisation.oci-containers.containers.comfyui.extraOptions = [
            "--device=/dev/kfd"
            "--device=${cfg.renderDevice}"
            # Numeric ids: the image's own group names do not match the host's.
            "--group-add=${toString config.users.groups.video.gid}"
            "--group-add=${toString config.users.groups.render.gid}"
          ];
        };
    };
  };
}
