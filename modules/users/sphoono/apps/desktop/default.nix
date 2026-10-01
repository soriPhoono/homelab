{ den, ... }: {
  den.aspects.sphoono.configs.desktop = {
    includes = [
      den.aspects.sphoono.gpg
      den.aspects.sphoono.ssh
      den.aspects.sphoono.configs.zen-browser
    ];
  };
}
