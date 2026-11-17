{
  # Adds a boot entry running the LTS kernel. Pick it when the default
  # kernel panics; zen 7.3.4 oopsed in process_one_work during early boot.
  den.aspects.core.bootloaders.lts-fallback.nixos =
    { lib, pkgs, ... }:
    {
      specialisation.lts-kernel.configuration.boot.kernelPackages = lib.mkForce pkgs.linuxPackages;
    };
}
