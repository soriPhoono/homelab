/**
  WinBoat: Windows apps on Linux, from a dockur/windows VM in a container.

  Runs on the user's rootless Podman rather than rootful Docker, so the VM
  and its disk belong to this user. The host must include
  `hosting.podman`, which provides the Podman system plumbing and projects
  `services.podman` onto this home. The nixpkgs package already puts
  podman-compose and FreeRDP on WinBoat's PATH.

  All state is under /home (~/.winboat and Podman's storage in
  ~/.local/share/containers), so impermanence needs no declarations.
*/
{
  den.aspects.sphoono.core.winboat = {
    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        jq = lib.getExe pkgs.jq;
      in
      {
        home.packages = [ pkgs.winboat ];

        # WinBoat writes winboat.config.json itself, so it cannot be a store
        # symlink. Set the container runtime in place on every activation and
        # leave the other keys to the app; WinBoat fills in missing keys from
        # its defaults when it reads the file. Unparseable JSON is left alone,
        # and WinBoat falls back to its defaults for it.
        home.activation.winboatPodman = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          dir=${lib.escapeShellArg "${config.home.homeDirectory}/.winboat"}
          cfg="$dir/winboat.config.json"
          if [[ ! -v DRY_RUN ]]; then
            mkdir -p "$dir"
            if [[ -s "$cfg" ]]; then
              tmp="$(mktemp "$dir/.winboat.config.json.XXXXXX")"
              if ${jq} '.containerRuntime = "Podman"' "$cfg" > "$tmp"; then
                mv "$tmp" "$cfg"
              else
                rm -f "$tmp"
              fi
            else
              ${jq} -n '{ containerRuntime: "Podman" }' > "$cfg"
            fi
          fi
        '';

        assertions = [
          {
            assertion = config.services.podman.enable;
            message = "sphoono.core.winboat runs on rootless Podman; include hosting.podman on the host.";
          }
        ];
      };
  };
}
