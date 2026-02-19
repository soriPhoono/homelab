______________________________________________________________________

## description: Verify changes, rebuild system, and push to git

1. Run Nix flake checks to ensure configuration is valid
   // turbo
   nix flake check

1. Run security audit (Ensure all problems are non-dangerous at runtime)
   // turbo
   nix run .#audit

1. Rebuild NixOS system
   nh os switch

1. Check git status
   // turbo
   git status

1. Stage all changes
   git add .

1. Check git diff for all changes available
   git diff --staged

1. Commit changes (Replace commit message with suitable description based on the diff)
   git commit -m "<commit message>"

1. Push changes to remote
   git push
