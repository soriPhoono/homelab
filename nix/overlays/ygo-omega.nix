{inputs, ...}: _final: prev: let
  version = "2026-08-03";
  basePkg = inputs.ygo-nix.packages.${prev.stdenv.hostPlatform.system}.default;
  gameFiles = prev.fetchurl {
    url = "https://github.com/duelists-unite/omega-releases/releases/download/Latest/linux-x64.zip";
    hash = "sha256-k9QGnU1PMm5YGcFy9RR0Tdhe9mPXdp18AvTJp7a7U14=";
  };
  launcherFiles = prev.fetchurl {
    url = "https://github.com/duelists-unite/omega-releases/releases/download/Latest/Omega_Launcher-Linux.zip";
    hash = "sha256-e7RHLRp/LGae4Z912oBlsTpPQrMCjXlsd18zQIxZVfo=";
  };
in {
  ygo-omega = basePkg.overrideAttrs (_old: {
    inherit version;
    __intentionallyOverridingVersion = true;

    unpackPhase = ''
      runHook preUnpack
      unzip -q ${gameFiles}
      unzip -q ${launcherFiles}
      runHook postUnpack
    '';
  });
}
