{lib, ...}: let
  users = {
    soriphoono = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEgxxFcqHVwYhY0TjbsqByOYpmWXqzlVyGzpKjqS8mO7";
  };

  # Per-user secrets: simple mapping of secret name -> list of users
  userSecrets = {
    # example = [ "soriphoono" ];
    test = ["soriphoono"];
  };

  # Team secrets: for shared access across multiple users
  teams = {
    cloud = {
      users = ["soriphoono"];
      secrets = ["test2"];
    };
  };

  # Helper: create a secret entry with public keys
  mkSecret = name: userList: {
    name = "secrets/${name}.age";
    value.publicKeys = map (user: users.${user}) userList;
  };

  # Collect secrets from teams
  teamSecretsList = lib.concatLists (
    lib.attrValues (lib.mapAttrs' (
        _: team: {
          name = "team";
          value = map (secret: mkSecret secret team.users) team.secrets;
        }
      )
      teams)
  );

  # Collect per-user secrets
  userSecretsList = lib.attrValues (
    lib.mapAttrs' (secret: userList: mkSecret secret userList) userSecrets
  );

  # Shell secrets for agenix-shell (filtered by current user)
  currentUser = builtins.getEnv "USER";
  userTeams = lib.filter (team: lib.elem currentUser team.users) (lib.attrValues teams);
  userOwnSecrets = lib.attrNames (lib.filterAttrs (_: userList: lib.elem currentUser userList) userSecrets);

  agenix-shell-secrets = lib.concatLists [
    # Secrets from teams the user belongs to
    (lib.concatLists (map (
        team:
          map (secret: {
            name = builtins.toUpper secret;
            value.file = ./secrets/${secret}.age;
          })
          team.secrets
      )
      userTeams))
    # Per-user secrets the user has access to
    (map (secret: {
        name = lib.toUpper secret;
        value.file = ./secrets/${secret}.age;
      })
      userOwnSecrets)
  ];
in
  {
    inherit agenix-shell-secrets;
  }
  // lib.listToAttrs (teamSecretsList ++ userSecretsList)
