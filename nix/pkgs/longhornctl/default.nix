{
  lib,
  stdenvNoCC,
  fetchurl,
}: let
  version = "1.11.1";
  pname = "longhornctl";

  assets = {
    x86_64-linux = {
      url = "https://github.com/longhorn/cli/releases/download/v${version}/longhornctl-linux-amd64";
      hash = "sha256-Kyplu1z25in1as7vulzCuh3qOaX9TJvZggSOfqSiSyk=";
    };
    aarch64-linux = {
      url = "https://github.com/longhorn/cli/releases/download/v${version}/longhornctl-linux-arm64";
      hash = "sha256-IScjffcQx8ajtM7qRHLanmV1Z++ZYtPpeSGybvdvvsw=";
    };
    x86_64-darwin = {
      url = "https://github.com/longhorn/cli/releases/download/v${version}/longhornctl-darwin-amd64";
      hash = "sha256-KYTZC9GdP7sbtPJMvG8/OBLEo4bgOmL3+FoOPoIJQPU=";
    };
    aarch64-darwin = {
      url = "https://github.com/longhorn/cli/releases/download/v${version}/longhornctl-darwin-arm64";
      hash = "sha256-bfzVPNKeg+5nlVkN98freC1bTItPxfRC7ISGFh872mI=";
    };
  };

  asset = assets.${stdenvNoCC.hostPlatform.system} or null;
in
  assert lib.assertMsg (asset != null) "longhornctl: unsupported system ${stdenvNoCC.hostPlatform.system}";
    stdenvNoCC.mkDerivation {
      inherit pname version;

      src = fetchurl {
        inherit (asset) url;
        inherit (asset) hash;
      };

      dontUnpack = true;

      installPhase = ''
        runHook preInstall
        install -Dm755 "$src" "$out/bin/longhornctl"
        runHook postInstall
      '';

      meta = {
        description = "Longhorn command-line tool for cluster install, checks, and troubleshooting";
        homepage = "https://github.com/longhorn/cli";
        license = lib.licenses.asl20;
        mainProgram = "longhornctl";
        sourceProvenance = [lib.sourceTypes.binaryNativeCode];
        platforms = lib.attrNames assets;
      };
    }
