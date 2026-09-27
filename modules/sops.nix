# sops-nix wiring for every host and home. Secrets are declared next to the
# aspect that consumes them, e.g. in a host aspect:
#
#   den.aspects.laptop-ares.nixos.sops.secrets.foo.sopsFile = ../../../secrets/laptop-ares.yaml;
#
# Encrypted files live in ./secrets and are governed by ./.sops.yaml.
{ inputs, ... }:
{
  den.default = {
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
}
