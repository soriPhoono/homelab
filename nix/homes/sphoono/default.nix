{config, ...}: {
  imports = [
    ./configs

    ./theme.nix
  ];

  core = {
    shells.shellAliases = {
      lzg = "${config.programs.lazygit.package}/bin/lazygit";
      gs = "git status";
      ga = "git add";
      gc = "git commit -m";
      gch = "git checkout -b";
      gp = "git push";
      gpl = "git pull";
    };

    email = {
      enable = true;
      accounts = {
        personal = {
          address = "soriphoono@gmail.com";
          primary = true;
        };
      };
    };

    secrets.defaultSopsFile = ./secrets.yml;

    apps.git = {
      enable = true;
      userName = "soriphoono";
    };
  };
}
