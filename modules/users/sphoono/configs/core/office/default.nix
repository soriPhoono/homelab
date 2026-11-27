{ den, ... }: {
  den.aspects.sphoono.core.office = {
    includes = [
      den.aspects.sphoono.core.office.calibre
      den.aspects.sphoono.core.office.libreoffice
      den.aspects.sphoono.core.office.qbittorrent
      den.aspects.sphoono.core.office.zathura
    ];
  };
}
