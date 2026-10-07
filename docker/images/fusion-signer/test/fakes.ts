import { mkdtempSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type { Config } from "../src/config.js";
import type {
  BuiltOrder,
  Chain,
  Fusion,
  FusionStatus,
  QuoteSummary,
} from "../src/ports.js";
import { Service, type Deps } from "../src/service.js";
import { Store } from "../src/state.js";
import { LOP_V4, TOKENS } from "../src/tokens.js";

export const SIGNER = "0x00000000000000000000000000000000000000A1";
export const METAMASK = "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed";
/** A checksummed address standing in for the 1inch settlement contract. */
export const SETTLEMENT = "0x1111111254EEB25477B68fb85Ed929f73A960582";
export const RPC_URL = "https://base.example/v2/rpc-secret-key";

export class FakeChain implements Chain {
  readonly address = SIGNER;
  balances = new Map<string, bigint>();
  allowances = new Map<string, bigint>();
  eth = 10n ** 16n;
  sent: { kind: string; token?: string; to: string; amount: bigint }[] = [];
  failSend = false;

  async chainId() {
    return 8453;
  }
  async decimals(token: string) {
    return Object.values(TOKENS).find((t) => t.address === token)!.decimals;
  }
  async balance(token: string) {
    return this.balances.get(token) ?? 0n;
  }
  async ethBalance() {
    return this.eth;
  }
  async allowance(token: string, spender: string) {
    return spender === LOP_V4 ? (this.allowances.get(token) ?? 0n) : 0n;
  }
  async approve(token: string, spender: string, amount: bigint) {
    this.sent.push({ kind: "approve", token, to: spender, amount });
    return "0xapprove";
  }
  async transfer(token: string, to: string, amount: bigint) {
    if (this.failSend) throw new Error(`rpc ${RPC_URL} timed out`);
    this.sent.push({ kind: "transfer", token, to, amount });
    return "0xtransfer";
  }
  async sendEth(to: string, amount: bigint) {
    if (this.failSend) throw new Error(`rpc ${RPC_URL} timed out`);
    this.sent.push({ kind: "eth", to, amount });
    return "0xeth";
  }
  async gasCost(kind: "erc20" | "eth") {
    return kind === "eth" ? 10n ** 12n : 3n * 10n ** 12n;
  }
}

/** Fills at `price` USD per asset unit, `bps` worse than it. */
export class FakeFusion implements Fusion {
  price = 100_000;
  bps = 20;
  receiver: string | undefined;
  settlement: string | undefined;
  hang = false;
  submits = 0;
  failSubmit = false;
  gate: Promise<void> | undefined;
  nextStatus: FusionStatus | undefined;

  private out(from: string, amount: bigint): bigint {
    const worse = 1 - this.bps / 1e4;
    const btc = TOKENS.BTC.decimals;
    if (from === TOKENS.USDC.address) {
      const usd = Number(amount) / 1e6;
      return BigInt(Math.floor((usd / this.price) * worse * 10 ** btc));
    }
    const units = Number(amount) / 10 ** btc;
    return BigInt(Math.floor(units * this.price * worse * 1e6));
  }

  async quote(from: string, _to: string, amount: bigint) {
    const end = this.out(from, amount);
    return { startAmount: end + end / 100n, endAmount: end } as QuoteSummary;
  }

  async build(from: string, to: string, amount: bigint): Promise<BuiltOrder> {
    if (this.hang) await new Promise<never>(() => undefined);
    if (this.gate) await this.gate;
    return {
      summary: {
        hash: "0x" + "cd".repeat(32),
        maker: SIGNER,
        receiver: this.receiver ?? SIGNER,
        settlement: this.settlement ?? SETTLEMENT,
        makerAsset: from,
        takerAsset: to,
        makingAmount: amount,
        takingAmount: this.out(from, amount),
      },
      submit: async () => {
        if (this.failSubmit) throw new Error(`relay via ${RPC_URL} failed`);
        this.submits += 1;
        return "0x" + "cd".repeat(32);
      },
    };
  }

  async status(): Promise<FusionStatus> {
    return this.nextStatus!;
  }
}

export const testConfig = (over: Partial<Config> = {}): Config => ({
  dryRun: false,
  limits: {
    maxOrderUsd: 60,
    maxDailyUsd: 150,
    defaultMaxSlippageBps: 100,
    minOrderIntervalSec: 60,
  },
  withdrawAddress: METAMASK,
  settlementAddress: SETTLEMENT,
  ethGasReserve: "0.0003",
  dataDir: mkdtempSync(join(tmpdir(), "fusion-signer-")),
  port: 0,
  secrets: {
    privateKey: "0x" + "11".repeat(32),
    token: "t".repeat(64),
    oneinchApiKey: "oneinch-secret-key",
    rpcUrl: RPC_URL,
  },
  ...over,
});

export function makeService(over: Partial<Deps> = {}) {
  const config = over.config ?? testConfig();
  const chain = new FakeChain();
  chain.balances.set(TOKENS.USDC.address, 100_000_000n);
  chain.allowances.set(TOKENS.USDC.address, 150_000_000n);
  const fusion = new FakeFusion();
  let now = Date.UTC(2026, 9, 7, 12);
  const deps: Deps = {
    config,
    store: new Store(config.dataDir, () => now),
    chain,
    fusion,
    reference: async () => 100_000,
    now: () => now,
    ...over,
  };
  const advance = (ms: number) => {
    now += ms;
  };
  return { service: new Service(deps), deps, chain, fusion, advance };
}
