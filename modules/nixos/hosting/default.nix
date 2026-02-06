{lib, ...}:
with lib; {
  imports = [
    ./backends
    ./features

    ./single-node.nix
  ];

  options.hosting = {
    mode = mkOption {
      type = with types; nullOr (enum ["single-node"]);
      description = "The mode to run hosting services, via single-node based systems.";
      default = null;
      example = "single-node";
    };
  };
}
