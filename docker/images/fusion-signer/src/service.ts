import { createHash } from "node:crypto";
import type { Config } from "./config.js";
import { HttpError, redact } from "./errors.js";
import { checkLimits, checkOrder } from "./guard.js";
import type { Chain, Fusion } from "./ports.js";
import type { Reference } from "./reference.js";
import type { Store } from "./state.js";
import {
  LOP_V4,
  TOKENS,
  fromRaw,
  toRaw,
  type Asset,
  type Token,
} from "./tokens.js";
import type { OrderRequest, QuoteRequest, Side } from "./validate.js";

export interface Result {
  status: number;
  body: Record<string, unknown>;
}

export interface Deps {
  config: Config;
  store: Store;
  chain: Chain;
  fusion: Fusion;
  reference: Reference;
  now: () => number;
}

export const bodyHash = (value: unknown): string =>
  createHash("sha256").update(JSON.stringify(value)).digest("hex");

const upstream = (err: unknown, what: string): HttpError =>
  new HttpError(502, "upstream", `${what}: ${(err as Error).message}`);

export class Service {
  private readonly inFlight = new Set<string>();

  constructor(private readonly d: Deps) {}

  private secrets(): string[] {
    return Object.values(this.d.config.secrets);
  }

  /** Runs `run` once per requestId and stores the outcome. */
  protected async once(
    requestId: string,
    hash: string,
    run: () => Promise<Result>,
  ): Promise<Result> {
    const stored = this.d.store.getRequest(requestId);
    if (stored) {
      if (stored.bodyHash !== hash) {
        throw new HttpError(
          409,
          "request_id_conflict",
          "requestId was used with a different request",
        );
      }
      return { status: stored.status, body: stored.body as Result["body"] };
    }
    if (this.inFlight.has(requestId)) {
      throw new HttpError(
        409,
        "request_in_progress",
        "requestId is still being processed",
      );
    }
    this.inFlight.add(requestId);
    try {
      let result: Result;
      try {
        result = await run();
      } catch (err) {
        if (!(err instanceof HttpError) || err.status === 400) throw err;
        const error = redact(err.message, this.secrets());
        result = { status: err.status, body: { error, reason: err.reason } };
      }
      this.d.store.putRequest(requestId, { bodyHash: hash, ...result });
      return result;
    } finally {
      this.inFlight.delete(requestId);
    }
  }

  protected tokensFor(side: Side, asset: Asset) {
    return side === "buy"
      ? { sell: TOKENS.USDC, buy: TOKENS[asset] }
      : { sell: TOKENS[asset], buy: TOKENS.USDC };
  }

  protected parseAmount(amount: string, decimals: number): bigint {
    try {
      return toRaw(amount, decimals);
    } catch {
      throw new HttpError(
        400,
        "invalid_body",
        `amount has more than ${decimals} decimals`,
      );
    }
  }

  protected async sellAmount(req: QuoteRequest, sell: Token) {
    const a = req.amount;
    if ("usdc" in a) return this.parseAmount(a.usdc, TOKENS.USDC.decimals);
    if ("units" in a) return this.parseAmount(a.units, sell.decimals);
    const balance = await this.d.chain.balance(sell.address);
    return (balance * BigInt(Math.round(a.fraction * 1e6))) / 1_000_000n;
  }

  async placeOrder(req: OrderRequest): Promise<Result> {
    const { store, chain, fusion, config } = this.d;
    if (store.isHalted()) {
      throw new HttpError(423, "halted", "signer is halted");
    }
    return this.once(req.requestId, bodyHash(req), async () => {
      const { sell, buy } = this.tokensFor(req.side, req.asset);
      const refPrice = await this.d.reference(req.asset);
      const sellAmount = await this.sellAmount(req, sell);
      const sellUnits = Number(fromRaw(sellAmount, sell.decimals));
      const notionalUsd = sellUnits * (req.side === "buy" ? 1 : refPrice);
      checkLimits({
        limits: config.limits,
        notionalUsd,
        dailyUsd: store.dailyUsd(),
        lastOrderAt: store.lastOrderAt(req.asset),
        nowMs: this.d.now(),
        sellAmount,
        balance: await chain.balance(sell.address),
        allowance: await chain.allowance(sell.address, LOP_V4),
      });
      const built = await fusion.build(sell.address, buy.address, sellAmount);
      const check = checkOrder(built.summary, {
        side: req.side,
        asset: req.asset,
        maker: chain.address,
        sellToken: sell,
        buyToken: buy,
        sellAmount,
        refPrice,
        maxSlippageBps:
          req.maxSlippageBps ?? config.limits.defaultMaxSlippageBps,
      });
      const detail = {
        requestId: req.requestId,
        side: req.side,
        asset: req.asset,
        sellToken: sell.symbol,
        sellAmount: fromRaw(sellAmount, sell.decimals),
        buyToken: buy.symbol,
        minBuyAmount: fromRaw(built.summary.takingAmount, buy.decimals),
        notionalUsd,
        refPrice,
        worstPrice: check.worstPrice,
        slippageBps: check.slippageBps,
      };
      if (config.dryRun) {
        return { status: 200, body: { ...detail, status: "dry_run" } };
      }
      store.addDailyUsd(notionalUsd);
      store.setLastOrderAt(req.asset, this.d.now());
      let orderHash: string;
      try {
        orderHash = await built.submit();
      } catch (err) {
        throw upstream(err, "submit failed");
      }
      return {
        status: 200,
        body: { ...detail, orderHash, status: "pending" },
      };
    });
  }
}
