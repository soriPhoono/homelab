{ inputs, pkgs }:
let
  version = "1.1.0";
in
{
  # The Lua half, loaded into the user's own editor for the annotation keymaps.
  vimPlugin = pkgs.vimUtils.buildVimPlugin {
    pname = "herdr-nvim";
    inherit version;
    src = inputs.herdr-nvim;
  };

  # The herdr plugin directory: the Rust sidebar daemon plus the manifest and
  # Lua runtime it appends to the sidebar nvim's runtimepath.
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
      mkdir -p $out/plugin-root
      cp -r lua plugin doc herdr-plugin.toml $out/plugin-root/
      mkdir -p $out/plugin-root/bin
      ln -s $out/bin/herdr-nvim $out/plugin-root/bin/herdr-nvim
    '';
  };
}
