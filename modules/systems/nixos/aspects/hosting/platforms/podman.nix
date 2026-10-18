/**
  Rootless Podman for per-user containers, such as AI agents.

  The nixos half provides the system plumbing (subuid/subgid, setuid
  helpers); host-aspects projects the homeManager half onto each user, so a
  host including this aspect is enough for its users to declare their own
  containers under `services.podman`.
*/
{
  den.aspects.hosting.podman = {
    nixos = {
      imports = [
        ./_private/tailscale-bypass.nix
      ];

      virtualisation.podman = {
        enable = true;
        autoPrune.enable = true;
      };

      # Per-user Docker-compatible API socket for tools that talk to it.
      systemd.user.sockets.podman.wantedBy = [ "sockets.target" ];
    };

    homeManager = {
      services.podman.enable = true;
    };
  };
}
