{inputs, ...}: let
  # Import mkVscodeModule directly from the home-manager source so we can
  # override the dataFolderName for Antigravity IDE v2.0, which moved from
  # .antigravity → .antigravity-ide.
  mkVscodeModule = import "${inputs.home-manager}/modules/programs/vscode/mkVscodeModule.nix";
in {
  # Drop the upstream version at home-manager/modules/programs/antigravity.nix
  disabledModules = ["programs/antigravity.nix"];

  imports = [
    (mkVscodeModule {
      modulePath = ["programs" "antigravity"];
      name = "Antigravity";
      packageName = "antigravity";
      nameShort = "Antigravity";
      dataFolderName = ".antigravity-ide";
      skipVersionCheck = true;
    })
  ];
}
