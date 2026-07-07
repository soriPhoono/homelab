{inputs, ...}: _final: _prev: {
  google-antigravity = inputs.antigravity-nix.packages.x86_64-linux.google-antigravity-no-fhs;
  google-antigravity-ide = inputs.antigravity-nix.packages.x86_64-linux.google-antigravity-ide-no-fhs;
  google-antigravity-cli = inputs.antigravity-nix.packages.x86_64-linux.google-antigravity-cli-no-fhs;
}
