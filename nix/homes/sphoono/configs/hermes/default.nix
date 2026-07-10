{pkgs, ...}: {
  apps.development.agents.hermes = {
    enableCli = true;
    enableDesktop = true;

    environment = {
      HELLO = "WORLD";
    };

    extraPackages = with pkgs; [
      cowsay
    ];

    secrets = [
      "api/EXA_API_KEY"
    ];

    profiles.default = {
      extraPackages = with pkgs; [
        hello
      ];

      secrets = [
        "api/BRAVE_API_KEY"
      ];

      environment = {
        WORK = "TEST";
      };

      documents = {
        soul = ./documents/default/soul.md;
      };
    };
  };
}
