sed -i 's/build-nixos-node:/build-nixos-docker-node:/g' .github/workflows/ci.yml
sed -i 's/nixosConfigurations.node/nixosConfigurations.docker-node/g' .github/workflows/ci.yml
sed -i 's/nixpkgs-droid.url = "github:NixOS\/nixpkgs\/88d3861";/nixpkgs-droid.url = "github:NixOS\/nixpkgs\/nixos-unstable";/' flake.nix
git add .github/workflows/ci.yml flake.nix
git commit -m "fix(ci): fix docker-node workflow and update nixpkgs-droid"
