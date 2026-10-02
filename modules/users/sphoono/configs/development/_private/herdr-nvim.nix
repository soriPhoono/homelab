{ inputs, pkgs }:
let
  version = "1.1.0";
in
{
  # Lua half, loaded into the user's own editor for the annotation keymaps.
  vimPlugin = pkgs.vimUtils.buildVimPlugin {
    pname = "herdr-nvim";
    inherit version;
    src = inputs.herdr-nvim;
  };

  # The herdr plugin directory: manifest, Lua runtime and the Rust sidebar
  # daemon at bin/herdr-nvim.
  herdrPlugin = pkgs.rustPlatform.buildRustPackage {
    pname = "herdr-nvim-plugin";
    inherit version;
    src = inputs.herdr-nvim;
    cargoLock.lockFile = "${inputs.herdr-nvim}/Cargo.lock";
    nativeBuildInputs = with pkgs; [
      cmake
      pkg-config
    ];
    buildInputs = with pkgs; [
      openssl
      zlib
    ];
    doCheck = false;
    postInstall = ''
      mkdir -p $out/plugin/bin
      cp -r lua plugin doc herdr-plugin.toml $out/plugin/
      ln -s $out/bin/herdr-nvim $out/plugin/bin/herdr-nvim
    '';
  };
}
