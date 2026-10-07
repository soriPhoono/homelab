/**
 * Loads and validates the service configuration at startup.
 *
 * Non-secret settings come from environment variables in the stack file, so
 * changing a limit is a reviewed commit plus a deploy; no API can change
 * them. Secrets come from Docker Swarm secret files under /run/secrets and
 * are never taken from the environment. Every check fails closed: a bad
 * value stops the process before it can sign anything.
 */
import { readFileSync } from "node:fs";
import { getAddress } from "ethers";
import { toRaw } from "./tokens.js";

/** The hard limits the guard enforces on every order (guard.ts). */
export interface Limits {
  /** Largest single order in USD at the Coinbase reference price. */
  maxOrderUsd: number;
  /** Largest total of submitted orders per UTC day, in USD. */
  maxDailyUsd: number;
  /**
   * Worst-case fill allowed against the reference price, in basis points.
   * Requests may pass a smaller value but never a larger one.
   */
  defaultMaxSlippageBps: number;
  /** Minimum gap between two orders for the same asset, in seconds. */
  minOrderIntervalSec: number;
}

/** Secret values, read from Swarm secret files. Never logged or returned. */
export interface Secrets {
  /** Private key of the signer's wallet (`fusion_signer_key`). */
  privateKey: string;
  /** Bearer token n8n must send (`fusion_signer_token`, 32+ chars). */
  token: string;
  /** 1inch Dev Portal API key (`oneinch_api_key`). */
  oneinchApiKey: string;
  /** Base RPC URL; usually embeds a provider key (`base_rpc_url`). */
  rpcUrl: string;
}

/** Everything the service needs, after validation. */
export interface Config {
  /** True unless DRY_RUN is exactly "false": nothing is signed or sent. */
  dryRun: boolean;
  limits: Limits;
  /** The only address withdrawals ever go to (the user's MetaMask). */
  withdrawAddress: string;
  /**
   * 1inch Fusion settlement contract every order must use (checked by the
   * guard). Verified on Basescan by the user before deploy.
   */
  settlementAddress: string;
  /** ETH (decimal string) a partial native-ETH withdrawal must leave behind. */
  ethGasReserve: string;
  /** Directory for persistent state and the halt file (a Docker volume). */
  dataDir: string;
  /** HTTP port the server listens on inside the container network. */
  port: number;
  secrets: Secrets;
}

/** Environment variables, as `process.env` provides them. */
export type Env = Record<string, string | undefined>;

/**
 * Reads one secret by its Swarm secret name. Injected so tests can supply
 * values without touching the filesystem.
 */
export type ReadSecret = (name: string) => string;

/** Production `ReadSecret`: reads `/run/secrets/<name>` (used by main.ts). */
export const fileSecret: ReadSecret = (name) =>
  readFileSync(`/run/secrets/${name}`, "utf8");

/** Parse `raw` as a finite number greater than zero, naming `name` on error. */
const positive = (name: string, raw: string): number => {
  const value = Number(raw);
  if (!Number.isFinite(value) || value <= 0) {
    throw new Error(`${name} must be a positive number`);
  }
  return value;
};

/** Numeric env var with a default when it is unset; validated by `positive`. */
const num = (env: Env, name: string, fallback: number): number =>
  env[name] === undefined ? fallback : positive(name, env[name]);

/**
 * Read and trim one secret. The error names the secret but never includes a
 * value, so a misconfiguration cannot leak another secret into the logs.
 */
const secret = (read: ReadSecret, name: string): string => {
  let value: string;
  try {
    value = read(name).trim();
  } catch {
    throw new Error(`secret ${name} is missing`);
  }
  if (!value) throw new Error(`secret ${name} is empty`);
  return value;
};

/**
 * Require an address given exactly in EIP-55 checksummed form. An
 * all-lowercase address is rejected too, so a typo in a hand-entered address
 * is caught by the checksum.
 */
const checksummedAddress = (name: string, raw: string | undefined): string => {
  let checksummed: string;
  try {
    checksummed = getAddress(raw ?? "");
  } catch {
    throw new Error(`${name} is not a valid address`);
  }
  if (checksummed !== raw) {
    throw new Error(`${name} must be EIP-55 checksummed`);
  }
  return checksummed;
};

/**
 * Validate ETH_GAS_RESERVE as a positive decimal with at most 18 decimals,
 * the same parser withdrawals use later, so a value like "1e-3" fails here
 * instead of breaking every withdrawal at runtime.
 */
const gasReserve = (raw: string): string => {
  positive("ETH_GAS_RESERVE", raw);
  try {
    if (toRaw(raw, 18) <= 0n) throw new Error("zero");
  } catch {
    throw new Error(
      "ETH_GAS_RESERVE must be a positive decimal with at most 18 decimals",
    );
  }
  return raw;
};

/**
 * Build the validated `Config` from the environment and secret files.
 * Called once by main.ts; throws on the first invalid value.
 *
 * Defaults: DRY_RUN on, MAX_ORDER_USD 60, MAX_DAILY_USD 150,
 * DEFAULT_MAX_SLIPPAGE_BPS 100, MIN_ORDER_INTERVAL_SEC 60,
 * ETH_GAS_RESERVE "0.0003", DATA_DIR /data, PORT 8080.
 * WITHDRAW_ADDRESS and FUSION_SETTLEMENT_ADDRESS have no default.
 */
export function loadConfig(env: Env, read: ReadSecret): Config {
  const address = checksummedAddress("WITHDRAW_ADDRESS", env.WITHDRAW_ADDRESS);
  const settlement = checksummedAddress(
    "FUSION_SETTLEMENT_ADDRESS",
    env.FUSION_SETTLEMENT_ADDRESS,
  );
  const reserve = gasReserve(env.ETH_GAS_RESERVE ?? "0.0003");
  const token = secret(read, "fusion_signer_token");
  if (token.length < 32) {
    throw new Error("secret fusion_signer_token is shorter than 32 chars");
  }
  return {
    dryRun: env.DRY_RUN !== "false",
    limits: {
      maxOrderUsd: num(env, "MAX_ORDER_USD", 60),
      maxDailyUsd: num(env, "MAX_DAILY_USD", 150),
      defaultMaxSlippageBps: num(env, "DEFAULT_MAX_SLIPPAGE_BPS", 100),
      minOrderIntervalSec: num(env, "MIN_ORDER_INTERVAL_SEC", 60),
    },
    withdrawAddress: address,
    settlementAddress: settlement,
    ethGasReserve: reserve,
    dataDir: env.DATA_DIR ?? "/data",
    port: num(env, "PORT", 8080),
    secrets: {
      privateKey: secret(read, "fusion_signer_key"),
      token,
      oneinchApiKey: secret(read, "oneinch_api_key"),
      rpcUrl: secret(read, "base_rpc_url"),
    },
  };
}

/**
 * Refuse a withdrawal address equal to the signer's own wallet; that would
 * make "withdraw" a no-op that only burns gas. Needs the wallet address, so
 * it runs in startupChecks (startup.ts) rather than in loadConfig.
 */
export function assertNotSelf(config: Config, ownAddress: string): void {
  if (getAddress(ownAddress) === config.withdrawAddress) {
    throw new Error("WITHDRAW_ADDRESS must not be the signer's own address");
  }
}
