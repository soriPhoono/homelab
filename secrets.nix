let
  secretsFunction = {lib, ...}: let
    users = {
      soriphoono = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEgxxFcqHVwYhY0TjbsqByOYpmWXqzlVyGzpKjqS8mO7";
    };

    # Per-user secrets: simple mapping of secret name -> list of users
    userSecrets = {
      # example = [ "soriphoono" ];
      github_token = ["soriphoono"];
    };

    # Team secrets: for shared access across multiple users
    teams = {
      default = {
        users = ["soriphoono"];
        secrets = [];
      };
    };

    # Helper: create a secret entry with public keys
    mkSecret = name: userList: {
      name = "secrets/${name}.age";
      value = {
        publicKeys = builtins.map (user: users.${user}) userList;
      };
    };

    # Collect secrets from teams
    teamSecretsList = builtins.concatLists (builtins.map (team: builtins.map (secret: mkSecret secret team.users) team.secrets) (builtins.attrValues teams));

    # Collect per-user secrets
    userSecretsList = builtins.map (secret: mkSecret secret userSecrets.${secret}) (builtins.attrNames userSecrets);

    # Shell secrets for agenix-shell (filtered by current user)
    # Fallback to soriphoono if USER is not set (e.g. in pure evaluation)
    envUser = builtins.getEnv "USER";
    currentUser =
      if envUser == ""
      then "soriphoono"
      else envUser;
    userTeams = builtins.filter (team: builtins.elem currentUser team.users) (builtins.attrValues teams);
    userOwnSecrets = builtins.attrNames (lib.filterAttrs (_: userList: builtins.elem currentUser userList) userSecrets);

    agenix-shell-secrets = lib.listToAttrs (builtins.concatLists [
      # Secrets from teams the user belongs to
      (builtins.concatLists (builtins.map (
          team:
            builtins.map (secret: {
              name = lib.toUpper secret;
              value.file = ./secrets/${secret}.age;
            })
            team.secrets
        )
        userTeams))
      # Per-user secrets the user has access to
      (builtins.map (secret: {
          name = lib.toUpper secret;
          value.file = ./secrets/${secret}.age;
        })
        userOwnSecrets)
    ]);
  in
    {
      inherit agenix-shell-secrets;
    }
    // builtins.listToAttrs (teamSecretsList ++ userSecretsList);

  # Minimal lib for the default call (used by agenix CLI or pure import)
  libMinimal = {
    inherit (builtins) listToAttrs concatLists;
    mapAttrs' = f: set:
      builtins.listToAttrs (builtins.map (n: f n set.${n}) (builtins.attrNames set));
    filterAttrs = f: set:
      builtins.listToAttrs (builtins.map (n: {
        name = n;
        value = set.${n};
      }) (builtins.filter (n: f n set.${n}) (builtins.attrNames set)));
    # agenix CLI doesn't need toUpper, so we provide a dummy or skip it
    toUpper = s: s;
  };
in
  (secretsFunction {lib = libMinimal;})
  // {
    __functor = _: secretsFunction;
  }
