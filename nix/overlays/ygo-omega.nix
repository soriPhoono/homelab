{inputs, ...}: _final: prev: let
  basePkg = inputs.ygo-nix.packages.${prev.stdenv.hostPlatform.system}.default;
  gameFiles = prev.fetchurl {
    url = "https://github.com/duelists-unite/omega-releases/releases/download/Latest/linux-x64.zip";
    hash = "sha256-tati0tA5L3a3pInTlsSa1Lgd15mvyspEsEG6r178Sec=";
  };
  launcherFiles = prev.fetchurl {
    url = "https://github.com/duelists-unite/omega-releases/releases/download/Latest/Omega_Launcher-Linux.zip";
    hash = "sha256-e7RHLRp/LGae4Z912oBlsTpPQrMCjXlsd18zQIxZVfo=";
  };
in {
  ygo-omega = basePkg.overrideAttrs (_old: {
    unpackPhase = ''
      runHook preUnpack
      unzip -q ${gameFiles}
      unzip -q ${launcherFiles}
      runHook postUnpack
    '';
  });
}
