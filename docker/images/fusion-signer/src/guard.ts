import type { Limits } from "./config.js";
import { HttpError } from "./errors.js";
import type { OrderSummary } from "./ports.js";
import { TOKENS, fromRaw, type Asset, type Token } from "./tokens.js";
import type { Side } from "./validate.js";

const refuse = (reason: string, message: string): never => {
  throw new HttpError(403, reason, message);
};

export interface PreChecks {
  limits: Limits;
  notionalUsd: number;
  dailyUsd: number;
  lastOrderAt: number | undefined;
  nowMs: number;
  sellAmount: bigint;
  balance: bigint;
  allowance: bigint;
}

/** Guard checks 4 to 8 of the spec, in order. */
export function checkLimits(c: PreChecks): void {
  const usd = (n: number) => `$${n.toFixed(2)}`;
  if (!(
    Number.isFinite(c.notionalUsd) &&
    c.notionalUsd >= 0 &&
    c.notionalUsd <= c.limits.maxOrderUsd
  )) {
    refuse(
      "order_cap",
      `order ${usd(c.notionalUsd)} exceeds ${usd(c.limits.maxOrderUsd)}`,
    );
  }
  if (!(c.dailyUsd + c.notionalUsd <= c.limits.maxDailyUsd)) {
    refuse(
      "daily_cap",
      `today ${usd(c.dailyUsd)} + ${usd(c.notionalUsd)} exceeds ` +
        usd(c.limits.maxDailyUsd),
    );
  }
  const gapMs = c.limits.minOrderIntervalSec * 1000;
  if (!(c.lastOrderAt === undefined || c.nowMs - c.lastOrderAt >= gapMs)) {
    refuse("too_soon", "previous order for this asset was too recent");
  }
  if (c.sellAmount <= 0n || c.sellAmount > c.balance) {
    refuse("insufficient_balance", "balance does not cover the order");
  }
  if (c.sellAmount > c.allowance) {
    refuse("insufficient_allowance", "approve the token first");
  }
}

/** USD per whole asset unit implied by a USDC and an asset amount. */
export function unitPrice(
  usdcRaw: bigint,
  assetRaw: bigint,
  asset: Token,
): number {
  const usdc = Number(fromRaw(usdcRaw, TOKENS.USDC.decimals));
  return usdc / Number(fromRaw(assetRaw, asset.decimals));
}

/** Positive bps = worse than the reference for this side. */
export function slippageBps(side: Side, price: number, ref: number): number {
  return side === "buy" ? (price / ref - 1) * 1e4 : (1 - price / ref) * 1e4;
}

export interface Expected {
  side: Side;
  asset: Asset;
  maker: string;
  settlement: string;
  sellToken: Token;
  buyToken: Token;
  sellAmount: bigint;
  refPrice: number;
  maxSlippageBps: number;
}

/** Guard checks 9 and 10, on the order that would be signed. */
export function checkOrder(
  o: OrderSummary,
  e: Expected,
): { worstPrice: number; slippageBps: number } {
  const same = (a: string, b: string) => a.toLowerCase() === b.toLowerCase();
  const matches =
    same(o.maker, e.maker) &&
    same(o.receiver, e.maker) &&
    same(o.settlement, e.settlement) &&
    same(o.makerAsset, e.sellToken.address) &&
    same(o.takerAsset, e.buyToken.address) &&
    o.makingAmount === e.sellAmount;
  if (!matches) {
    refuse("order_mismatch", "built order does not match the request");
  }
  if (o.takingAmount <= 0n) {
    refuse("slippage", "taking amount must be positive");
  }
  if (!(Number.isFinite(e.refPrice) && e.refPrice > 0)) {
    refuse("slippage", "reference price must be finite and positive");
  }
  const asset = TOKENS[e.asset];
  const worstPrice =
    e.side === "buy"
      ? unitPrice(o.makingAmount, o.takingAmount, asset)
      : unitPrice(o.takingAmount, o.makingAmount, asset);
  const bps = slippageBps(e.side, worstPrice, e.refPrice);
  if (!(bps <= e.maxSlippageBps)) {
    refuse("slippage", `worst case is ${bps.toFixed(1)} bps from Coinbase`);
  }
  return { worstPrice, slippageBps: bps };
}
