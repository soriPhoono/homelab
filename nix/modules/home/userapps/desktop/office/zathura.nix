{
  lib,
  config,
  ...
}: let
  cfg = config.userapps.desktop.office.zathura;
in
  with lib; {
    options.userapps.desktop.office.zathura = {
      enable = mkEnableOption "Enable Zathura PDF reader";
      priority = mkOption {
        type = types.int;
        default = 0;
        description = "The priority of Zathura for being the default PDF reader. Lower is higher priority.";
      };
    };

    config = mkIf cfg.enable {
      programs.zathura.enable = true;

      xdg.mimeApps.defaultApplications = lib.mkIf config.userapps.defaultApplications.enable (let
        pdfReader = ["org.pwmt.zathura.desktop"];
      in
        mkOverride cfg.priority {
          "application/pdf" = pdfReader;
        });
    };
  }
