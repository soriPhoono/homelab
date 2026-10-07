import { createHash } from "node:crypto";
import type { Config } from "./config.js";
import { HttpError, redact } from "./errors.js";
import { checkLimits, checkOrder, slippageBps, unitPrice } from "./guard.js";
import type { Chain, Fusion } from "./ports.js";
import type { Reference } from "./reference.js";
import type { Store } from "./state.js";
import {
  CHAIN_ID,
  LOP_V4,
  TOKENS,
  fromRaw,
  toRaw,
  tokenByAddress,
  type Asset,
  type Token,
  type TokenKey,
} from "./tokens.js";
import type {
  ApproveRequest,
  HaltRequest,
  OrderRequest,
  QuoteRequest,
  Side,
  WithdrawRequest,
} from "./validate.js";
import { VERSION } from "./version.js";

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
  private queue: Promise<unknown> = Promise.resolve();

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
      const turn = this.queue.then(async (): Promise<Result> => {
        try {
          return await run();
        } catch (err) {
          const e =
            err instanceof HttpError
              ? err
              : new HttpError(502, "upstream", (err as Error).message);
          if (e.status === 400) throw e;
          const error = redact(e.message, this.secrets());
          return { status: e.status, body: { error, reason: e.reason } };
        }
      });
      this.queue = turn.catch(() => undefined);
      const result = await turn;
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
    const hash = bodyHash(req);
    return this.once(req.requestId, hash, async () => {
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
      // Intent marker: a retry after a crash finds it and does not resubmit.
      store.putRequest(req.requestId, {
        bodyHash: hash,
        status: 202,
        body: { ...detail, status: "submitting" },
      });
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

  async status(): Promise<Result> {
    const { chain, config, store } = this.d;
    const balances: Record<string, string> = {};
    const allowances: Record<string, string> = {};
    for (const t of Object.values(TOKENS)) {
      balances[t.key] = fromRaw(await chain.balance(t.address), t.decimals);
      const allowed = await chain.allowance(t.address, LOP_V4);
      allowances[t.key] = fromRaw(allowed, t.decimals);
    }
    balances.GAS = fromRaw(await chain.ethBalance(), 18);
    return {
      status: 200,
      body: {
        address: chain.address,
        chainId: CHAIN_ID,
        balances,
        allowances,
        limits: config.limits,
        dailyUsd: store.dailyUsd(),
        dryRun: config.dryRun,
        halted: store.isHalted(),
        withdrawAddress: config.withdrawAddress,
        version: VERSION,
      },
    };
  }

  async quote(req: QuoteRequest): Promise<Result> {
    const { sell, buy } = this.tokensFor(req.side, req.asset);
    const refPrice = await this.d.reference(req.asset);
    const amount = await this.sellAmount(req, sell);
    if (amount <= 0n) {
      throw new HttpError(403, "insufficient_balance", "nothing to sell");
    }
    const q = await this.d.fusion.quote(sell.address, buy.address, amount);
    const asset = TOKENS[req.asset];
    const price = (out: bigint) =>
      req.side === "buy"
        ? unitPrice(amount, out, asset)
        : unitPrice(out, amount, asset);
    const worstPrice = price(q.endAmount);
    return {
      status: 200,
      body: {
        side: req.side,
        asset: req.asset,
        sellToken: sell.symbol,
        sellAmount: fromRaw(amount, sell.decimals),
        buyToken: buy.symbol,
        startAmount: fromRaw(q.startAmount, buy.decimals),
        endAmount: fromRaw(q.endAmount, buy.decimals),
        refPrice,
        startPrice: price(q.startAmount),
        worstPrice,
        slippageBps: slippageBps(req.side, worstPrice, refPrice),
      },
    };
  }

  async orderStatus(hash: string): Promise<Result> {
    const s = await this.d.fusion.status(hash);
    const maker = tokenByAddress(s.makerAsset);
    const taker = tokenByAddress(s.takerAsset);
    if (!maker || !taker) {
      throw new HttpError(502, "upstream", "order uses unknown tokens");
    }
    const sum = (key: "makerAmount" | "takerAmount") =>
      s.fills.reduce((n, f) => n + f[key], 0n);
    const sold = sum("makerAmount");
    const bought = sum("takerAmount");
    const asset = maker.key === "USDC" ? taker : maker;
    let effectivePrice: number | null = null;
    if (sold > 0n && bought > 0n) {
      effectivePrice =
        maker.key === "USDC"
          ? unitPrice(sold, bought, asset)
          : unitPrice(bought, sold, asset);
    }
    return {
      status: 200,
      body: {
        orderHash: hash,
        status: s.status,
        sellToken: maker.symbol,
        soldAmount: fromRaw(sold, maker.decimals),
        buyToken: taker.symbol,
        boughtAmount: fromRaw(bought, taker.decimals),
        effectivePrice,
        fills: s.fills.map((f) => ({
          txHash: f.txHash,
          soldAmount: fromRaw(f.makerAmount, maker.decimals),
          boughtAmount: fromRaw(f.takerAmount, taker.decimals),
        })),
      },
    };
  }

  async approve(req: ApproveRequest): Promise<Result> {
    const { config, chain } = this.d;
    if (this.d.store.isHalted()) {
      throw new HttpError(423, "halted", "signer is halted");
    }
    const token = TOKENS[req.asset];
    const capMicro = BigInt(Math.round(config.limits.maxDailyUsd * 1e6));
    let amount = capMicro;
    if (req.asset !== "USDC") {
      const priceMicro = BigInt(
        Math.round((await this.d.reference(req.asset)) * 1e6),
      );
      if (priceMicro <= 0n) {
        throw new HttpError(403, "no_reference", "reference price unusable");
      }
      amount = (capMicro * 10n ** BigInt(token.decimals)) / priceMicro;
    }
    const detail = {
      asset: req.asset,
      token: token.symbol,
      spender: LOP_V4,
      amount: fromRaw(amount, token.decimals),
    };
    if (config.dryRun) {
      return { status: 200, body: { ...detail, status: "dry_run" } };
    }
    let txHash: string;
    try {
      txHash = await chain.approve(token.address, LOP_V4, amount);
    } catch (err) {
      throw upstream(err, "approve failed");
    }
    return { status: 200, body: { ...detail, status: "sent", txHash } };
  }

  async withdraw(req: WithdrawRequest): Promise<Result> {
    const hash = bodyHash(req);
    return this.once(req.requestId, hash, async () => {
      const { chain, config } = this.d;
      const to = config.withdrawAddress;
      const isGas = req.asset === "GAS";
      const token = isGas ? undefined : TOKENS[req.asset as TokenKey];
      const decimals = token?.decimals ?? 18;
      const balance = token
        ? await chain.balance(token.address)
        : await chain.ethBalance();
      const gas = await chain.gasCost(isGas ? "eth" : "erc20");
      const all = "all" in req.amount;
      const refuse = (reason: string, message: string): never => {
        throw new HttpError(403, reason, message);
      };
      if (isGas && all && balance <= gas) {
        refuse("no_gas", "not enough ETH to pay for the transfer");
      }
      const amount =
        "all" in req.amount
          ? isGas
            ? balance - gas
            : balance
          : this.parseAmount(req.amount.units, decimals);
      if (amount <= 0n || amount > balance) {
        refuse("insufficient_balance", "balance does not cover it");
      }
      if (isGas && !all) {
        const reserve = toRaw(config.ethGasReserve, 18);
        if (balance - amount < reserve) {
          refuse("gas_reserve", "would leave less than ETH_GAS_RESERVE");
        }
        if (balance - amount < gas) {
          refuse("no_gas", "not enough ETH left to pay for the transfer");
        }
      }
      if (!isGas && (await chain.ethBalance()) < gas) {
        refuse("no_gas", "not enough ETH to pay for the transfer");
      }
      const detail = {
        requestId: req.requestId,
        asset: req.asset,
        token: token?.symbol ?? "ETH",
        to,
        amount: fromRaw(amount, decimals),
      };
      if (config.dryRun) {
        return { status: 200, body: { ...detail, status: "dry_run" } };
      }
      // Intent marker: a retry after a crash finds it and does not resend.
      this.d.store.putRequest(req.requestId, {
        bodyHash: hash,
        status: 202,
        body: { ...detail, status: "sending" },
      });
      let txHash: string;
      try {
        txHash = token
          ? await chain.transfer(token.address, to, amount)
          : await chain.sendEth(to, amount);
      } catch (err) {
        throw upstream(err, "withdraw failed");
      }
      return { status: 200, body: { ...detail, status: "sent", txHash } };
    });
  }

  async halt(req: HaltRequest): Promise<Result> {
    this.d.store.halt(req.reason);
    return { status: 200, body: { halted: true } };
  }
}
