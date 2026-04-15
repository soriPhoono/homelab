{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.desktop.office.libreoffice;
in
  with lib; {
    options.userapps.desktop.office.libreoffice = {
      enable = mkEnableOption "Enable LibreOffice desktop suite";

      priority = mkOption {
        type = types.int;
        default = 10;
        description = "Priority for being the default office application. Lower is higher priority.";
      };
    };

    config = mkIf cfg.enable {
      home.packages = [
        pkgs.libreoffice-fresh
        pkgs.hunspell
        pkgs.hunspellDicts.en_US
      ];

      xdg.mimeApps.defaultApplications = lib.mkIf config.userapps.defaultApplications.enable (let
        writer = ["libreoffice-writer.desktop"];
        calc = ["libreoffice-calc.desktop"];
        impress = ["libreoffice-impress.desktop"];
        draw = ["libreoffice-draw.desktop"];
        math = ["libreoffice-math.desktop"];
        base = ["libreoffice-base.desktop"];
      in
        mkOverride cfg.priority {
          # Writer (Word Processing)
          "application/vnd.oasis.opendocument.text" = writer;
          "application/vnd.oasis.opendocument.text-template" = writer;
          "application/vnd.oasis.opendocument.text-web" = writer;
          "application/vnd.oasis.opendocument.text-master" = writer;
          "application/vnd.oasis.opendocument.text-master-template" = writer;
          "application/vnd.sun.xml.writer" = writer;
          "application/vnd.sun.xml.writer.template" = writer;
          "application/vnd.sun.xml.writer.global" = writer;
          "application/vnd.stardivision.writer" = writer;
          "application/vnd.stardivision.writer-global" = writer;
          "application/x-extension-txt" = writer;
          "application/x-t602" = writer;
          "text/plain" = writer;
          "application/vnd.oasis.opendocument.text-flat-xml" = writer;
          "application/x-fictionbook+xml" = writer;
          "application/macwriteii" = writer;
          "application/x-aportisdoc" = writer;
          "application/prs.plucker" = writer;
          "application/vnd.apple.pages" = writer;
          "application/x-iwork-pages-sffpages" = writer;
          "application/vnd.palm" = writer;
          "application/x-sony-bbeb" = writer;
          "application/x-hwp" = writer;
          "application/x-abiword" = writer;
          "application/vnd.wordperfect" = writer;
          "application/wordperfect" = writer;
          "application/msword" = writer;
          "application/vnd.ms-word" = writer;
          "application/x-doc" = writer;
          "application/x-mswrite" = writer;
          "application/rtf" = writer;
          "text/rtf" = writer;
          "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = writer;
          "application/vnd.ms-word.document.macroEnabled.12" = writer;
          "application/vnd.openxmlformats-officedocument.wordprocessingml.template" = writer;
          "application/vnd.ms-word.template.macroEnabled.12" = writer;
          "application/vnd.ms-works" = writer;
          "application/vnd.lotus-wordpro" = writer;

          # Calc (Spreadsheets)
          "application/vnd.oasis.opendocument.spreadsheet" = calc;
          "application/vnd.oasis.opendocument.spreadsheet-template" = calc;
          "application/vnd.sun.xml.calc" = calc;
          "application/vnd.sun.xml.calc.template" = calc;
          "application/vnd.stardivision.calc" = calc;
          "application/vnd.stardivision.chart" = calc;
          "application/vnd.oasis.opendocument.spreadsheet-flat-xml" = calc;
          "application/vnd.ms-excel" = calc;
          "application/msexcel" = calc;
          "application/x-msexcel" = calc;
          "application/x-ms-excel" = calc;
          "application/x-excel" = calc;
          "application/x-dos_ms_excel" = calc;
          "application/xls" = calc;
          "application/x-xls" = calc;
          "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = calc;
          "application/vnd.ms-excel.sheet.macroEnabled.12" = calc;
          "application/vnd.openxmlformats-officedocument.spreadsheetml.template" = calc;
          "application/vnd.ms-excel.template.macroEnabled.12" = calc;
          "application/vnd.ms-excel.sheet.binary.macroEnabled.12" = calc;
          "application/vnd.apple.numbers" = calc;
          "application/x-iwork-numbers-sffnumbers" = calc;
          "application/x-quattropro" = calc;
          "application/x-123" = calc;
          "application/vnd.lotus-1-2-3" = calc;
          "application/csv" = calc;
          "text/csv" = calc;
          "text/x-csv" = calc;
          "text/x-comma-separated-values" = calc;
          "text/comma-separated-values" = calc;
          "application/tab-separated-values" = calc;
          "text/tab-separated-values" = calc;
          "application/x-dbf" = calc;
          "application/x-dbase" = calc;

          # Impress (Presentations)
          "application/vnd.oasis.opendocument.presentation" = impress;
          "application/vnd.oasis.opendocument.presentation-template" = impress;
          "application/vnd.sun.xml.impress" = impress;
          "application/vnd.sun.xml.impress.template" = impress;
          "application/vnd.stardivision.impress" = impress;
          "application/vnd.oasis.opendocument.presentation-flat-xml" = impress;
          "application/mspowerpoint" = impress;
          "application/vnd.ms-powerpoint" = impress;
          "application/vnd.openxmlformats-officedocument.presentationml.presentation" = impress;
          "application/vnd.ms-powerpoint.presentation.macroEnabled.12" = impress;
          "application/vnd.openxmlformats-officedocument.presentationml.template" = impress;
          "application/vnd.ms-powerpoint.template.macroEnabled.12" = impress;
          "application/vnd.openxmlformats-officedocument.presentationml.slide" = impress;
          "application/vnd.openxmlformats-officedocument.presentationml.slideshow" = impress;
          "application/vnd.ms-powerpoint.slideshow.macroEnabled.12" = impress;
          "application/vnd.apple.keynote" = impress;
          "application/x-iwork-keynote-sffkey" = impress;

          # Draw (Vector Graphics / PDF)
          "application/vnd.oasis.opendocument.graphics" = draw;
          "application/vnd.oasis.opendocument.graphics-template" = draw;
          "application/vnd.sun.xml.draw" = draw;
          "application/vnd.sun.xml.draw.template" = draw;
          "application/vnd.stardivision.draw" = draw;
          "application/vnd.oasis.opendocument.graphics-flat-xml" = draw;
          "application/vnd.visio" = draw;
          "application/x-wpg" = draw;
          "application/vnd.corel-draw" = draw;
          "application/vnd.ms-publisher" = draw;
          "application/x-pagemaker" = draw;
          "application/vnd.quark.quarkxpress" = draw;
          "image/x-freehand" = draw;
          "image/x-wmf" = draw;
          "image/x-emf" = draw;

          # Math (Formulas)
          "application/vnd.oasis.opendocument.formula" = math;
          "application/vnd.oasis.opendocument.formula-template" = math;
          "application/vnd.sun.xml.math" = math;
          "application/vnd.stardivision.math" = math;
          "application/mathml+xml" = math;
          "text/mathml" = math;

          # Base (Databases)
          "application/vnd.oasis.opendocument.base" = base;
          "application/vnd.sun.xml.base" = base;
        });
    };
  }
