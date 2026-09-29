# sops-nix wiring for every host and home. Secrets are declared next to the
# aspect that consumes them, e.g. in a host aspect:
#
#   den.aspects.laptop-ares.nixos.sops.secrets.foo.sopsFile = ../../../secrets/laptop-ares.yaml;
#
# Encrypted files live in ./secrets and are governed by ./.sops.yaml.
{ inputs, ... }:
{
  config = {
    flake-file.inputs.sops-nix.url = "github:Mic92/sops-nix";
    den = {
      default = {
        nixos = {
          imports = [ inputs.sops-nix.nixosModules.sops ];
          # Hosts decrypt with their SSH host key (converted to age by sops-nix).
          sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        };
        homeManager =
          { config, ... }:
          {
            imports = [ inputs.sops-nix.homeManagerModules.sops ];
            sops.age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
          };
      };
      schema = {
        host.includes = [
          (
            { host, ... }:
            {
              nixos.sops.defaultSopsFile = ../secrets/${host.name}.yaml;
            }
          )
        ];
        user.includes = [
          (
            { user, ... }:
            {
              nixos =
                { config, ... }:
                {
                  systemd.tmpfiles.rules = [
                    "d /home/${user.userName}/.config/ 0755 ${user.userName} ${user.userName} -"
                    "d /home/${user.userName}/.config/sops/ 0700 ${user.userName} ${user.userName} -"
                    "d /home/${user.userName}/.config/sops/age/ 0700 ${user.userName} ${user.userName} -"
                  ];
                  sops.secrets = {
                    "users/${user.userName}/password".neededForUsers = true;
                    "users/${user.userName}/age-keys" = {
                      path = "/home/${user.userName}/.config/sops/age/keys.txt";
                      mode = "0400";
                      owner = user.userName;
                      group = user.userName;
                    };
                  };
                  # `or null` lets vm.nix drop the secret without breaking evaluation.
                  users = {
                    users.${user.userName}.hashedPasswordFile =
                      config.sops.secrets."users/${user.userName}/password".path or null;
                    groups.${user.userName}.members = [
                      user.userName
                    ];
                  };
                };
            }
          )
        ];
      };
    };
  };
}
