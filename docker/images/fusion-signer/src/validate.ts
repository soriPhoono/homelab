/**
 * Strict parsing of request bodies into typed requests.
 *
 * Everything is an allowlist: unknown fields, wrong types, unknown assets and
 * malformed numbers are rejected with 400 `invalid_body` before any service
 * code runs. Notably no request can carry a token or destination address.
 * Each `parse*` function is called by the matching route in server.ts.
 */
import { HttpError } from "./errors.js";
import type { Asset, Holding, TokenKey } from "./tokens.js";

/** "buy" swaps USDC into the asset; "sell" swaps the asset into USDC. */
export type Side = "buy" | "sell";

/**
 * How much to trade.
 * - `{ usdc }`: buy only, the USDC to spend (decimal string).
 * - `{ units }`: sell only, the asset amount to sell (decimal string).
 * - `{ fraction }`: sell only, a share of the current balance in (0, 1].
 */
export type TradeAmount =
  { usdc: string } | { units: string } | { fraction: number };

/** How much to withdraw: an exact decimal amount, or the whole balance. */
export type WithdrawAmount = { units: string } | { all: true };

/** Body of `POST /quote`: price check only, nothing is signed. */
export interface QuoteRequest {
  side: Side;
  asset: Asset;
  amount: TradeAmount;
}

/** Body of `POST /orders`: a quote plus an idempotency key. */
export interface OrderRequest extends QuoteRequest {
  /** Caller-chosen id; repeating it replays the stored result. */
  requestId: string;
  /** Optional tighter slippage limit (bps); may not exceed the config. */
  maxSlippageBps?: number;
}

/** Body of `POST /withdraw`. The destination comes from config, never here. */
export interface WithdrawRequest {
  requestId: string;
  asset: Holding;
  amount: WithdrawAmount;
}

/** Body of `POST /approve`: which token to approve for the 1inch contract. */
export interface ApproveRequest {
  asset: TokenKey;
}

/** Body of `POST /halt`: free-text reason recorded in the halt file. */
export interface HaltRequest {
  reason: string;
}

/** A parsed JSON object whose fields are still unchecked. */
type Obj = Record<string, unknown>;

/** Reject the request: throw a 400 `invalid_body` with `message`. */
const bad = (message: string): never => {
  throw new HttpError(400, "invalid_body", message);
};

/** Require `v` to be a plain object (not null, not an array). */
const object = (v: unknown, what: string): Obj => {
  if (typeof v !== "object" || v === null || Array.isArray(v)) {
    return bad(`${what} must be an object`);
  }
  return v as Obj;
};

/** Reject any field of `o` that is not in `allowed`. */
const onlyKeys = (o: Obj, allowed: string[], what: string): void => {
  for (const k of Object.keys(o)) {
    if (!allowed.includes(k)) bad(`${what}: unknown field ${k}`);
  }
};

/** Require `v` to be one of the listed string values. */
const oneOf = <T extends string>(
  v: unknown,
  values: readonly T[],
  what: string,
): T => {
  if (typeof v !== "string" || !values.includes(v as T)) {
    return bad(`${what} must be one of ${values.join(", ")}`);
  }
  return v as T;
};

/**
 * Plain decimal: no sign, exponent, whitespace, leading zeros or trailing
 * dot. Amounts are strings so no float rounding happens before toRaw.
 */
const DECIMAL = /^(0|[1-9]\d*)(\.\d+)?$/;

/** Require a positive decimal string matching `DECIMAL`. */
const decimal = (v: unknown, what: string): string => {
  if (typeof v !== "string" || !DECIMAL.test(v) || Number(v) <= 0) {
    return bad(`${what} must be a positive decimal string`);
  }
  return v;
};

/** Allowed requestId: 1-64 chars, safe in URLs, logs and JSON keys. */
const REQUEST_ID = /^[A-Za-z0-9._:-]{1,64}$/;

/** Require a requestId matching `REQUEST_ID`. */
const requestId = (v: unknown): string => {
  if (typeof v !== "string" || !REQUEST_ID.test(v)) {
    return bad("requestId must be 1-64 chars of [A-Za-z0-9._:-]");
  }
  return v;
};

/**
 * Parse a trade amount for `side`: buys take only `{ usdc }`; sells take
 * `{ units }` or `{ fraction }` with 0 < fraction <= 1.
 */
const tradeAmount = (v: unknown, side: Side): TradeAmount => {
  const o = object(v, "amount");
  if (side === "buy") {
    onlyKeys(o, ["usdc"], "amount");
    return { usdc: decimal(o.usdc, "amount.usdc") };
  }
  if ("units" in o) {
    onlyKeys(o, ["units"], "amount");
    return { units: decimal(o.units, "amount.units") };
  }
  onlyKeys(o, ["fraction"], "amount");
  const f = o.fraction;
  if (typeof f !== "number" || !(f > 0 && f <= 1)) {
    return bad("amount.fraction must be in (0, 1]");
  }
  return { fraction: f };
};

/** The assets a quote or order may name. */
const ASSETS = ["BTC", "ETH"] as const;

/** Parse a `POST /quote` body. Also used by `parseOrder` for shared fields. */
export function parseQuote(body: unknown): QuoteRequest {
  const o = object(body, "body");
  onlyKeys(o, ["side", "asset", "amount"], "body");
  const side = oneOf(o.side, ["buy", "sell"] as const, "side");
  const asset = oneOf(o.asset, ASSETS, "asset");
  return { side, asset, amount: tradeAmount(o.amount, side) };
}

/**
 * Parse a `POST /orders` body. `maxSlippageBps` must be an integer from 1 to
 * 1000 here; the service additionally refuses anything above the configured
 * default, so a request can only tighten the limit.
 */
export function parseOrder(body: unknown): OrderRequest {
  const o = object(body, "body");
  const keys = ["requestId", "side", "asset", "amount", "maxSlippageBps"];
  onlyKeys(o, keys, "body");
  const id = requestId(o.requestId);
  const q = parseQuote({ side: o.side, asset: o.asset, amount: o.amount });
  const req: OrderRequest = { requestId: id, ...q };
  if (o.maxSlippageBps !== undefined) {
    const b = o.maxSlippageBps;
    if (typeof b !== "number" || !Number.isInteger(b) || b < 1 || b > 1000) {
      return bad("maxSlippageBps must be an integer from 1 to 1000");
    }
    req.maxSlippageBps = b;
  }
  return req;
}

/**
 * Parse a `POST /withdraw` body. There is deliberately no address field: an
 * extra field such as `to` is rejected as unknown.
 */
export function parseWithdraw(body: unknown): WithdrawRequest {
  const o = object(body, "body");
  onlyKeys(o, ["requestId", "asset", "amount"], "body");
  const id = requestId(o.requestId);
  const holdings = ["USDC", "BTC", "ETH", "GAS"] as const;
  const asset = oneOf(o.asset, holdings, "asset");
  const a = object(o.amount, "amount");
  if ("all" in a) {
    onlyKeys(a, ["all"], "amount");
    if (a.all !== true) return bad("amount.all must be true");
    return { requestId: id, asset, amount: { all: true } };
  }
  onlyKeys(a, ["units"], "amount");
  const units = decimal(a.units, "amount.units");
  return { requestId: id, asset, amount: { units } };
}

/** Parse a `POST /approve` body. Native ETH ("GAS") needs no approval. */
export function parseApprove(body: unknown): ApproveRequest {
  const o = object(body, "body");
  onlyKeys(o, ["asset"], "body");
  const keys = ["USDC", "BTC", "ETH"] as const;
  return { asset: oneOf(o.asset, keys, "asset") };
}

/** Parse a `POST /halt` body: a reason of 1-200 characters. */
export function parseHalt(body: unknown): HaltRequest {
  const o = object(body, "body");
  onlyKeys(o, ["reason"], "body");
  const r = o.reason;
  if (typeof r !== "string" || r.length < 1 || r.length > 200) {
    return bad("reason must be 1-200 chars");
  }
  return { reason: r };
}
