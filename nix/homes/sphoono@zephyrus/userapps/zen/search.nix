{pkgs, ...}: {
  userapps.browsers.zen.profileConfig.default.search = {
    force = true;
    default = "ddg";
    engines = let
      nixSnowflakeIcon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
    in {
      "Nix Packages" = {
        urls = [
          {
            template = "https://search.nixos.org/packages";
            params = [
              {
                name = "channel";
                value = "unstable";
              }
              {
                name = "query";
                value = "{searchTerms}";
              }
            ];
          }
        ];
        icon = nixSnowflakeIcon;
        definedAliases = ["@np"];
      };
      "Nix Options" = {
        urls = [
          {
            template = "https://search.nixos.org/options";
            params = [
              {
                name = "channel";
                value = "unstable";
              }
              {
                name = "query";
                value = "{searchTerms}";
              }
            ];
          }
        ];
        icon = nixSnowflakeIcon;
        definedAliases = ["@no"];
      };
      "Home Manager Options" = {
        urls = [
          {
            template = "https://home-manager-options.extranix.com/?release=master";
            params = [
              {
                name = "query";
                value = "{searchTerms}";
              }
            ];
          }
        ];
        icon = nixSnowflakeIcon;
        definedAliases = ["@hm"];
      };
      "NixOS Wiki" = {
        urls = [
          {
            template = "https://wiki.nixos.org/w/index.php";
            params = [
              {
                name = "search";
                value = "{searchTerms}";
              }
            ];
          }
        ];
        icon = nixSnowflakeIcon;
        definedAliases = ["@nw"];
      };
      "google".metaData.hidden = true;
      "bing".metaData.hidden = true;
      "amazon".metaData.hidden = true;
    };
  };
}
