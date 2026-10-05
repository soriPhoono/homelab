/**
  Local crypto trading services, reachable from the host only.

  - Freqtrade: algorithmic trading bot in dry-run (paper trading) mode, FreqUI
    on http://127.0.0.1:8080. The first start seeds a dry-run config.json with
    generated API credentials (read them from that file) and the upstream
    sample strategy.
*/
{ den, ... }:
{
  den.aspects.hosting.trading = {
    includes = [
      den.aspects.hosting.docker
    ];

    nixos =
      { lib, pkgs, ... }:
      let
        freqtrade = {
          image = "freqtradeorg/freqtrade:stable";
          userData = "/var/lib/freqtrade/user_data";
          # ftuser inside the image.
          owner = "1000:1000";
        };

        # Seed for user_data/config.json; credentials are filled in on first
        # start so none of them land in the nix store.
        freqtradeConfig = (pkgs.formats.json { }).generate "freqtrade-config.json" {
          dry_run = true;
          dry_run_wallet = 1000;
          stake_currency = "USDT";
          stake_amount = "unlimited";
          max_open_trades = 3;
          trading_mode = "spot";
          exchange = {
            name = "binance";
            key = "";
            secret = "";
            pair_whitelist = [
              "BTC/USDT"
              "ETH/USDT"
            ];
            pair_blacklist = [ ];
          };
          entry_pricing.price_side = "same";
          exit_pricing.price_side = "same";
          pairlists = [ { method = "StaticPairList"; } ];
          api_server = {
            enabled = true;
            # Inside the container; the host only publishes it on loopback.
            listen_ip_address = "0.0.0.0";
            listen_port = 8080;
            username = "freqtrader";
            password = "";
            jwt_secret_key = "";
            ws_token = "";
            CORS_origins = [ ];
          };
          bot_name = "freqtrade";
          initial_state = "running";
          internals.process_throttle_secs = 5;
        };
      in
      {
        systemd = {
          tmpfiles.rules = [
            "d ${freqtrade.userData} 0770 ${freqtrade.owner} -"
          ];

          # oci-containers already puts the docker CLI on this unit's PATH.
          services.docker-freqtrade.preStart = ''
            # Lay out user_data and deploy the sample strategy once.
            if [ ! -e ${freqtrade.userData}/strategies/sample_strategy.py ]; then
              docker run --rm \
                -v ${freqtrade.userData}:/freqtrade/user_data \
                ${freqtrade.image} \
                create-userdir --userdir /freqtrade/user_data
            fi

            if [ ! -e ${freqtrade.userData}/config.json ]; then
              secret() { head -c 32 /dev/urandom | base64 | tr -d '/+='; }
              umask 077
              ${lib.getExe pkgs.jq} \
                --arg password "$(secret)" \
                --arg jwt "$(secret)" \
                --arg ws "$(secret)" \
                '.api_server.password = $password
                  | .api_server.jwt_secret_key = $jwt
                  | .api_server.ws_token = $ws' \
                ${freqtradeConfig} > ${freqtrade.userData}/config.json
              chown ${freqtrade.owner} ${freqtrade.userData}/config.json
            fi
          '';
        };

        virtualisation.oci-containers.containers = {
          freqtrade = {
            inherit (freqtrade) image;
            ports = [ "127.0.0.1:8080:8080" ];
            volumes = [ "${freqtrade.userData}:/freqtrade/user_data" ];
            cmd = [
              "trade"
              "--db-url"
              "sqlite:////freqtrade/user_data/tradesv3.sqlite"
              "--config"
              "/freqtrade/user_data/config.json"
              "--strategy"
              "SampleStrategy"
            ];
          };
        };
      };
  };
}
