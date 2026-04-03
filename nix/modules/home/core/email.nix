{
  lib,
  config,
  ...
}: let
  cfg = config.core.email;
in
  with lib; {
    options.core.email = {
      enable = lib.mkEnableOption "email";

      accounts = mkOption {
        type = with types;
          attrsOf (submodule {
            options = {
              address = mkOption {
                type = types.str;
                description = "The email address";
                example = "[EMAIL_ADDRESS]";
              };

              primary = mkEnableOption "Set this account as the primary email";
            };
          });
      };
    };

    # TODO: Set up automatic configuration of thunderbird with this module
    # TODO: also configure calendar and contacts with this system (called accounts)
    config = mkIf cfg.enable {
      assertions = [
        {
          assertion = lib.length (lib.filter (account: account.primary) (attrValues cfg.accounts)) == 1;
          message = "You must have exactly one primary email account";
        }
      ];

      accounts.email.accounts =
        lib.mapAttrs' (name: value: {
          name =
            if value.primary
            then "primary"
            else name;
          value = {
            inherit (value) primary address;
          };
        })
        cfg.accounts;
    };
  }
