import { describe, expect, it } from "vitest";
import {
  checkLimits,
  checkOrder,
  type Expected,
  type PreChecks,
} from "../src/guard.js";
import { HttpError } from "../src/errors.js";
import type { OrderSummary } from "../src/ports.js";
import { TOKENS } from "../src/tokens.js";

const reason = (fn: () => unknown): string => {
  try {
    fn();
  } catch (e) {
    expect(e).toBeInstanceOf(HttpError);
    expect((e as HttpError).status).toBe(403);
    return (e as HttpError).reason;
  }
  return "passed";
};

const base: PreChecks = {
  limits: {
    maxOrderUsd: 60,
    maxDailyUsd: 150,
    defaultMaxSlippageBps: 100,
    minOrderIntervalSec: 60,
  },
  notionalUsd: 25,
  dailyUsd: 0,
  lastOrderAt: undefined,
  nowMs: 1_000_000,
  sellAmount: 25_000_000n,
  balance: 50_000_000n,
  allowance: 150_000_000n,
};

describe("checkLimits", () => {
  it("passes at the boundaries", () => {
    expect(reason(() => checkLimits({ ...base, notionalUsd: 60 }))).toBe(
      "passed",
    );
    const at = { ...base, lastOrderAt: base.nowMs - 60_000 };
    expect(reason(() => checkLimits(at))).toBe("passed");
  });

  it("refuses in spec order", () => {
    const r = (c: Partial<PreChecks>) =>
      reason(() => checkLimits({ ...base, ...c }));
    expect(r({ notionalUsd: 60.01, sellAmount: 0n })).toBe("order_cap");
    expect(r({ dailyUsd: 130, sellAmount: 0n })).toBe("daily_cap");
    expect(r({ lastOrderAt: base.nowMs - 59_999 })).toBe("too_soon");
    expect(r({ sellAmount: 0n })).toBe("insufficient_balance");
    expect(r({ balance: 1n })).toBe("insufficient_balance");
    expect(r({ allowance: 1n })).toBe("insufficient_allowance");
  });
});

const MAKER = "0x00000000000000000000000000000000000000A1";

// Buy $50 of cbBTC; worst case 0.0004975 BTC => $100,502.51 per BTC.
const buyOrder: OrderSummary = {
  hash: "0x" + "ab".repeat(32),
  maker: MAKER,
  receiver: MAKER.toLowerCase(),
  makerAsset: TOKENS.USDC.address,
  takerAsset: TOKENS.BTC.address.toLowerCase(),
  makingAmount: 50_000_000n,
  takingAmount: 49_750n,
};

const expected: Expected = {
  side: "buy",
  asset: "BTC",
  maker: MAKER,
  sellToken: TOKENS.USDC,
  buyToken: TOKENS.BTC,
  sellAmount: 50_000_000n,
  refPrice: 100_000,
  maxSlippageBps: 100,
};

describe("checkOrder", () => {
  it("returns the worst price and slippage of a good buy", () => {
    const r = checkOrder(buyOrder, expected);
    expect(r.worstPrice).toBeCloseTo(100_502.51, 1);
    expect(r.slippageBps).toBeCloseTo(50.25, 1);
  });

  it("refuses slippage beyond the limit", () => {
    const tight = { ...expected, maxSlippageBps: 50 };
    expect(reason(() => checkOrder(buyOrder, tight))).toBe("slippage");
    const zero = { ...buyOrder, takingAmount: 0n };
    expect(reason(() => checkOrder(zero, expected))).toBe("slippage");
  });

  it("checks a sell against the bid side", () => {
    // Sell 0.0005 BTC for at least $49.60 => $99,200 per BTC, 80 bps.
    const sell: OrderSummary = {
      ...buyOrder,
      makerAsset: TOKENS.BTC.address,
      takerAsset: TOKENS.USDC.address,
      makingAmount: 50_000n,
      takingAmount: 49_600_000n,
    };
    const e: Expected = {
      ...expected,
      side: "sell",
      sellToken: TOKENS.BTC,
      buyToken: TOKENS.USDC,
      sellAmount: 50_000n,
    };
    expect(checkOrder(sell, e).slippageBps).toBeCloseTo(80, 1);
    const tight = { ...e, maxSlippageBps: 79 };
    expect(reason(() => checkOrder(sell, tight))).toBe("slippage");
  });

  it("refuses any mismatch with the request", () => {
    const other = "0x00000000000000000000000000000000000000B2";
    const cases: Partial<OrderSummary>[] = [
      { receiver: other },
      { maker: other },
      { makerAsset: TOKENS.ETH.address },
      { takerAsset: TOKENS.ETH.address },
      { makingAmount: 50_000_001n },
    ];
    for (const c of cases) {
      const r = reason(() => checkOrder({ ...buyOrder, ...c }, expected));
      expect(r).toBe("order_mismatch");
    }
  });
});
