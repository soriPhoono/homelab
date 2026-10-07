/**
 * The order guard: pure functions that refuse an order which breaks a limit
 * or does not match what was requested.
 *
 * No I/O happens here. Service gathers the inputs (balances, reference price,
 * the built order) and calls `checkLimits` before building the order and
 * `checkOrder` on the built order just before signing it. Every refusal is
 * an `HttpError(403, reason)`. Comparisons are written so a NaN or non-finite
 * input refuses instead of slipping through.
 */
import type { Limits } from "./config.js";
import { HttpError } from "./errors.js";
import type { OrderSummary } from "./ports.js";
import { TOKENS, fromRaw, type Asset, type Token } from "./tokens.js";
import type { Side } from "./validate.js";

/** Refuse the order: throw a 403 with the given reason code. */
const refuse = (reason: string, message: string): never => {
  throw new HttpError(403, reason, message);
};

/** Inputs to `checkLimits`, gathered by Service.placeOrder. */
export interface PreChecks {
  limits: Limits;
  /** Order size in USD at the reference price. */
  notionalUsd: number;
  /** USD already submitted today (Store.dailyUsd). */
  dailyUsd: number;
  /** Epoch ms of this asset's last order, if any (Store.lastOrderAt). */
  lastOrderAt: number | undefined;
  /** Current epoch ms. */
  nowMs: number;
  /** Raw amount of the token being sold. */
  sellAmount: bigint;
  /** Wallet balance of the token being sold. */
  balance: bigint;
  /** Allowance of the token being sold to the 1inch contract. */
  allowance: bigint;
}

/**
 * Guard checks 4 to 8 of the spec, in order: `order_cap`, `daily_cap`,
 * `too_soon`, `insufficient_balance`, `insufficient_allowance`.
 *
 * A zero-notional order passes the cap so that an empty sell is reported as
 * `insufficient_balance`, the more useful reason.
 */
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

/**
 * USD per whole asset unit implied by a USDC and an asset amount.
 * Example: 50 USDC for 0.0005 cbBTC -> 100000. Used for worst-case,
 * quoted and filled prices.
 */
export function unitPrice(
  usdcRaw: bigint,
  assetRaw: bigint,
  asset: Token,
): number {
  const usdc = Number(fromRaw(usdcRaw, TOKENS.USDC.decimals));
  return usdc / Number(fromRaw(assetRaw, asset.decimals));
}

/**
 * Positive bps = worse than the reference for this side.
 * A buy is worse when paying more than the reference; a sell is worse when
 * receiving less. A better-than-reference price gives negative bps.
 */
export function slippageBps(side: Side, price: number, ref: number): number {
  return side === "buy" ? (price / ref - 1) * 1e4 : (1 - price / ref) * 1e4;
}

/** What the built order must match, as derived by Service from the request. */
export interface Expected {
  side: Side;
  asset: Asset;
  /** The signer's address: required as both maker and receiver. */
  maker: string;
  /** The configured settlement contract (FUSION_SETTLEMENT_ADDRESS). */
  settlement: string;
  sellToken: Token;
  buyToken: Token;
  sellAmount: bigint;
  /** Coinbase reference price in USD. */
  refPrice: number;
  /** Largest allowed worst-case slippage, bps. */
  maxSlippageBps: number;
}

/**
 * Guard checks 9 and 10, on the order that would be signed.
 *
 * Refuses `order_mismatch` unless maker, receiver, settlement contract,
 * tokens and sell amount all match. Refuses `slippage` if the order's
 * worst-case fill (its minimum `takingAmount`) is further than
 * `maxSlippageBps` from the reference, or if the inputs are unusable.
 * Returns the worst-case price and its slippage for the response body.
 */
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
