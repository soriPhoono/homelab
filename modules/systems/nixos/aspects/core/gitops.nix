{
  inputs,
  den,
  lib,
  ...
}:
{
  flake-file.inputs.comin.url = "github:nlewo/comin";

  den.aspects.core.gitops = { host, ... }: {
    nixos = {
      imports = [ inputs.comin.nixosModules.comin ];
      services.comin = {
        enable = true;
        remotes = [
          {
            name = "origin";
            url = "https://www.github.com/soriPhoono/homelab.git";
            branches.main.name = "main";
          }
        ];
        desktop = lib.mkIf (host.hasAspect den.aspects.desktop) {
          enable = true;
          title = "Comin [GitOps Updates]";
        };
      };
    };
  };
}
