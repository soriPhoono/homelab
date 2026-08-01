{lib, ...}:
with lib; {
  imports = [
    ./agents
    ./appliances
    ./design
    ./editors
    ./inference
    ./infrastructure
    ./terminal
  ];

  config = {
    home.packages = with pkgs; [
      (python3.withPackages (python-pkgs:
        with python-pkgs; [
          # TODO: build out global python environment for agentic development
        ]))
      nodejs
      pnpm
    ];
  };
}
