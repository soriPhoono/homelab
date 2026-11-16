/**
  VR gaming on a Meta Quest 3, streamed from this machine over the network
  (or USB). Steam stays the launcher; the headset only displays.

  Include a sub-aspect for the streaming stack the host should run, or both:

  - `vr.wivrn`: WiVRn, an OpenXR runtime. Steam's OpenVR games are translated
    by the xrizer layer that the WiVRn package bundles, so SteamVR itself is
    not needed.
  - `vr.alvr`: ALVR, which streams a real SteamVR session. Install SteamVR
    from Steam; every OpenVR game and tool then runs unmodified.

  The base aspect adds the Steam gaming suite, adb, and SideQuest for
  installing the headset-side app.

  One-time setup, none of which Nix can do:

  1. Put the Quest in developer mode (Meta Horizon phone app).
  2. Install the headset-side app, either from the Meta store or sideloaded
     with SideQuest or `adb install`. WiVRn's dashboard can also install it
     over adb.
  3. Log out and back in once, so the Steam sandbox sees the OpenXR runtime
     (`PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES`).
  4. For ALVR, install SteamVR from Steam, then register the ALVR driver from
     the ALVR dashboard.

  Start the app of only one stack on the headset at a time. Both stacks
  edit the OpenVR configuration in `~/.config/openvr`, and the WiVRn server
  does so when a headset connects.

  Not verified against hardware: the VM shim has no GPU or headset, so this
  aspect is only checked to evaluate.
*/
{ den, ... }:
{
  den.aspects.desktop.domains.gaming.vr = {
    includes = [
      den.aspects.desktop.domains.gaming.desktop
      den.aspects.core.hardware.android
    ];

    # Registers the parent so its sub-aspects resolve.
    nixos = _: { };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          # Installs the headset-side app and manages the Quest over adb.
          sidequest
        ];
      };

    wivrn = {
      includes = [
        den.aspects.desktop.domains.gaming.vr
      ];

      nixos = {
        services.wivrn = {
          enable = true;
          # 9757 for the stream; avahi, which the module enables, opens
          # 5353 for the headset to discover the server.
          openFirewall = true;
          # Waits for the headset; it only rewrites the OpenXR and OpenVR
          # configuration once one connects.
          autoStart = true;
          # CAP_SYS_NICE for asynchronous reprojection.
          highPriority = true;
          # Lets Steam's pressure-vessel sandbox reach the runtime.
          steam.importOXRRuntimes = true;
        };
      };
    };

    alvr = {
      includes = [
        den.aspects.desktop.domains.gaming.vr
      ];

      nixos = {
        programs.alvr = {
          enable = true;
          # 9943 and 9944, TCP and UDP.
          openFirewall = true;
        };
      };
    };
  };
}
