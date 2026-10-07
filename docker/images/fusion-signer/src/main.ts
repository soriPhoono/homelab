/**
 * Entry point (`node dist/main.js`, the container's command).
 *
 * Wires the real dependencies together: config and secrets, the ethers
 * wallet, startup checks, the 1inch client, the store and the service, then
 * starts the HTTP server. Any startup failure prints one redacted JSON line
 * ({"event":"fatal",...}) and exits 1 so Swarm restarts the container.
 */
import { EthersChain } from "./adapters/ethers-chain.js";
import { FusionClient } from "./adapters/fusion-client.js";
import { fileSecret, loadConfig } from "./config.js";
import { redact } from "./errors.js";
import { makeReference } from "./reference.js";
import { buildServer } from "./server.js";
import { Service } from "./service.js";
import { startupChecks } from "./startup.js";
import { Store } from "./state.js";

/**
 * Secret values to scrub from log lines. Filled as soon as the config loads;
 * empty before that, which is safe because config errors never contain
 * secret values.
 */
let secrets: string[] = [];

/** Write one JSON log line to stdout with every secret redacted. */
const log = (line: Record<string, unknown>) =>
  console.log(redact(JSON.stringify(line), secrets));

/** Load config, check the environment, build everything and listen. */
async function main(): Promise<void> {
  const config = loadConfig(process.env, fileSecret);
  secrets = Object.values(config.secrets);
  const { privateKey, rpcUrl, oneinchApiKey, token } = config.secrets;
  const chain = EthersChain.connect(rpcUrl, privateKey);
  await startupChecks(chain, config);
  const fusion = new FusionClient(
    chain.address,
    privateKey,
    chain.provider,
    oneinchApiKey,
  );
  const service = new Service({
    config,
    store: new Store(config.dataDir),
    chain,
    fusion,
    reference: makeReference(),
    now: Date.now,
  });
  buildServer({ service, token, secrets, log }).listen(config.port, () =>
    log({
      ts: new Date().toISOString(),
      event: "listening",
      port: config.port,
      address: chain.address,
      dryRun: config.dryRun,
    }),
  );
}

main().catch((err: unknown) => {
  log({ event: "fatal", error: (err as Error).message });
  process.exit(1);
});
