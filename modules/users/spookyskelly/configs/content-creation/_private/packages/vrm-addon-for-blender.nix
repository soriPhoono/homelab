# VRM Add-on for Blender: imports and exports VRM, the avatar format Warudo
# and VRoid Studio use. This is the legacy-addon release; its top directory
# is the addon module, installed under scripts/addons.
{
  lib,
  stdenvNoCC,
  fetchzip,
}:
stdenvNoCC.mkDerivation rec {
  pname = "vrm-addon-for-blender";
  version = "4.10.5";

  src = fetchzip {
    url = "https://github.com/saturday06/VRM-Addon-for-Blender/releases/download/v${version}/VRM_Addon_for_Blender-${
      lib.replaceStrings [ "." ] [ "_" ] version
    }.zip";
    hash = "sha256-tXPfizZIohN2gbrGm/mDdFMxbZBAXg/MTWkJF+Eru3I=";
  };

  installPhase = ''
    runHook preInstall
    cp -r . $out
    runHook postInstall
  '';

  # Module name Blender registers the addon under.
  passthru.moduleName = "VRM_Addon_for_Blender-release";

  meta = {
    description = "VRM import, export and editing for Blender";
    homepage = "https://vrm-addon-for-blender.info";
    license = lib.licenses.mit;
  };
}
