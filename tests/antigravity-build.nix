{pkgs, ...}:
if pkgs.stdenv.hostPlatform.system == "x86_64-linux"
then pkgs.antigravity
else
  pkgs.runCommand "antigravity-skip" {} ''
    echo "Skipping Antigravity test on ${pkgs.stdenv.hostPlatform.system}"
    touch $out
  ''
