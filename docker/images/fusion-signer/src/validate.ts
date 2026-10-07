import { HttpError } from "./errors.js";
import type { Asset, Holding, TokenKey } from "./tokens.js";

export type Side = "buy" | "sell";
export type TradeAmount =
  { usdc: string } | { units: string } | { fraction: number };
export type WithdrawAmount = { units: string } | { all: true };

export interface QuoteRequest {
  side: Side;
  asset: Asset;
  amount: TradeAmount;
}

export interface OrderRequest extends QuoteRequest {
  requestId: string;
  maxSlippageBps?: number;
}

export interface WithdrawRequest {
  requestId: string;
  asset: Holding;
  amount: WithdrawAmount;
}

export interface ApproveRequest {
  asset: TokenKey;
}

export interface HaltRequest {
  reason: string;
}

type Obj = Record<string, unknown>;

const bad = (message: string): never => {
  throw new HttpError(400, "invalid_body", message);
};

const object = (v: unknown, what: string): Obj => {
  if (typeof v !== "object" || v === null || Array.isArray(v)) {
    return bad(`${what} must be an object`);
  }
  return v as Obj;
};

const onlyKeys = (o: Obj, allowed: string[], what: string): void => {
  for (const k of Object.keys(o)) {
    if (!allowed.includes(k)) bad(`${what}: unknown field ${k}`);
  }
};

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

const DECIMAL = /^(0|[1-9]\d*)(\.\d+)?$/;

const decimal = (v: unknown, what: string): string => {
  if (typeof v !== "string" || !DECIMAL.test(v) || Number(v) <= 0) {
    return bad(`${what} must be a positive decimal string`);
  }
  return v;
};

const REQUEST_ID = /^[A-Za-z0-9._:-]{1,64}$/;

const requestId = (v: unknown): string => {
  if (typeof v !== "string" || !REQUEST_ID.test(v)) {
    return bad("requestId must be 1-64 chars of [A-Za-z0-9._:-]");
  }
  return v;
};

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

const ASSETS = ["BTC", "ETH"] as const;

export function parseQuote(body: unknown): QuoteRequest {
  const o = object(body, "body");
  onlyKeys(o, ["side", "asset", "amount"], "body");
  const side = oneOf(o.side, ["buy", "sell"] as const, "side");
  const asset = oneOf(o.asset, ASSETS, "asset");
  return { side, asset, amount: tradeAmount(o.amount, side) };
}

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

export function parseApprove(body: unknown): ApproveRequest {
  const o = object(body, "body");
  onlyKeys(o, ["asset"], "body");
  const keys = ["USDC", "BTC", "ETH"] as const;
  return { asset: oneOf(o.asset, keys, "asset") };
}

export function parseHalt(body: unknown): HaltRequest {
  const o = object(body, "body");
  onlyKeys(o, ["reason"], "body");
  const r = o.reason;
  if (typeof r !== "string" || r.length < 1 || r.length > 200) {
    return bad("reason must be 1-200 chars");
  }
  return { reason: r };
}
