import { readFileSync } from "node:fs";
import { getAddress } from "ethers";
import { toRaw } from "./tokens.js";

export interface Limits {
  maxOrderUsd: number;
  maxDailyUsd: number;
  defaultMaxSlippageBps: number;
  minOrderIntervalSec: number;
}

export interface Secrets {
  privateKey: string;
  token: string;
  oneinchApiKey: string;
  rpcUrl: string;
}

export interface Config {
  dryRun: boolean;
  limits: Limits;
  withdrawAddress: string;
  settlementAddress: string;
  ethGasReserve: string;
  dataDir: string;
  port: number;
  secrets: Secrets;
}

export type Env = Record<string, string | undefined>;
export type ReadSecret = (name: string) => string;

export const fileSecret: ReadSecret = (name) =>
  readFileSync(`/run/secrets/${name}`, "utf8");

const positive = (name: string, raw: string): number => {
  const value = Number(raw);
  if (!Number.isFinite(value) || value <= 0) {
    throw new Error(`${name} must be a positive number`);
  }
  return value;
};

const num = (env: Env, name: string, fallback: number): number =>
  env[name] === undefined ? fallback : positive(name, env[name]);

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

export function assertNotSelf(config: Config, ownAddress: string): void {
  if (getAddress(ownAddress) === config.withdrawAddress) {
    throw new Error("WITHDRAW_ADDRESS must not be the signer's own address");
  }
}
