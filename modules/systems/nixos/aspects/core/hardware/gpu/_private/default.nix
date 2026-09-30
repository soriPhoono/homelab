/**
  Each gpu needs:
    - hardware.graphics.enable = true;
    - hardware.graphics.enable32Bit = true;
    - extraPackages with vulkan-loader, vulkan-validation-layers, vulkan-extension-layer
    - extraPackages32 with vulkan-loader
    - hardware acceleration packages (e.g. amdgpu, intel-media-driver)
    - OpenCL packages and platform specific GPGPU system (e.g. rocm, intel-media-driver)
*/
{ pkgs, ... }: {
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      vulkan-loader
      vulkan-validation-layers
      vulkan-extension-layer
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      vulkan-loader
    ];
  };
}
