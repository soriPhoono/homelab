_: {
  enable = true;

  workflows = {
    # A basic example of a workflow file
    # This workflow will run on every push or pull request to the main branch
    # ci = {
    #   name = "CI";
    #   on = {
    #     push = {
    #       branches = ["main"];
    #     };
    #     pullRequest = {
    #       branches = ["main"];
    #     };
    #   };
    #   jobs = {
    #     ci = {
    #       runsOn = "ubuntu-latest";
    #       steps = [
    #         {
    #           name = "Checkout code";
    #           uses = "actions/checkout@v4";
    #         }
    #         {
    #           name = "Setup Nix";
    #           uses = "DeterminateSystems/nix-installer-action@main";
    #         }
    #         {
    #           name = "Magic Nix Cache";
    #           uses = "DeterminateSystems/magic-nix-cache-action@main";
    #           with_ = {
    #             use-flakehub = false;
    #           };
    #         }
    #       ];
    #     };
    #   };
    # };
  };
}
