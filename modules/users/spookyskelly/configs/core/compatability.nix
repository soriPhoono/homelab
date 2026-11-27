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
  den.aspects.spookyskelly.core.winboat = {
    homeManager =
      {
        config,
        pkgs,
        ...
      }:
      {
        home.packages = [
          pkgs.winboat
          pkgs.wineWow64Packages.waylandFull
        ];

        assertions = [
          {
            assertion = config.services.podman.enable;
            message = "spookyskelly.core.winboat runs on rootless Podman; include hosting.podman on the host.";
          }
        ];
      };
  };
}
