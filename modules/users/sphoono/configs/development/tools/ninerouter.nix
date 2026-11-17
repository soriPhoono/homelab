/**
  The 9router inference gateway on sphoono-vps, shared by the agents. It is
  reached over the tailnet through docktail. Each agent reads the endpoint from
  `development.ninerouter.url` instead of repeating it.
*/
_: {
  den.aspects.sphoono.development.ninerouter.homeManager =
    { lib, ... }:
    {
      options.development.ninerouter.url = lib.mkOption {
        type = lib.types.str;
        default = "https://sphoono-vps-9router.xerus-augmented.ts.net/v1";
        description = "OpenAI-compatible endpoint of the 9router gateway.";
      };
    };
}
