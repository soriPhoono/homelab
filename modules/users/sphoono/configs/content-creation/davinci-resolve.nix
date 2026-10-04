{ den, ... }:
{
  den.aspects.sphoono.content-creation = {
    includes = [
      (den.batteries.unfree [ "davinci-resolve" ])
    ];

    # Discrete-GPU offload is genuinely driver-specific, unlike OBS's
    # plugins. DRI_PRIME=1 is a harmless Mesa-only hint, ignored whenever
    # GLVND routes elsewhere -- safe to always set. __GLX_VENDOR_LIBRARY_NAME
    # is not a hint: it forces GLVND to load that vendor's GLX library, and
    # on a machine without the NVIDIA driver that library doesn't exist, so
    # setting it unconditionally can break GLX init outright rather than
    # being ignored. Gate the NVIDIA pair on the host actually having the
    # aspect that installs that driver.
    homeManager =
      {
        host,
        pkgs,
        lib,
        ...
      }:
      let
        onAmd = host.hasAspect den.aspects.core.hardware.gpu.amd;
        onNvidia = host.hasAspect den.aspects.core.hardware.gpu.nvidia;
        davinci-resolve-wrapped = pkgs.symlinkJoin {
          name = "davinci-resolve";
          paths = [ pkgs.davinci-resolve ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/davinci-resolve \
              ${lib.optionalString onAmd "--set DRI_PRIME 1"} \
              ${lib.optionalString onNvidia "--set __NV_PRIME_RENDER_OFFLOAD 1 --set __GLX_VENDOR_LIBRARY_NAME nvidia"}
          '';
        };
      in
      {
        home.packages = [ davinci-resolve-wrapped ];
      };
  };
}
