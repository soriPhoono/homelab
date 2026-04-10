{
  config,
  nvimConfigurations,
  ...
}: {
  imports = [
    ./configs
  ];

  core = {
    shells = {
      bash.enable = true;
      shellAliases = {
        lzg = "${config.programs.lazygit.package}/bin/lazygit";
        gs = "git status";
        ga = "git add";
        gc = "git commit -m";
        gch = "git checkout -b";
        gp = "git push";
        gpl = "git pull";
      };
    };

    secrets.defaultSopsFile = ./secrets.yml;
    apps.git = {
      enable = true;
      userName = "soriphoono";
    };
  };

  userapps.development.editors.neovim = {
    package = nvimConfigurations.sphoono;
  };
}
