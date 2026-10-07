import { describe, expect, it } from "vitest";
import { HttpError } from "../src/errors.js";
import {
  parseApprove,
  parseHalt,
  parseOrder,
  parseQuote,
  parseWithdraw,
} from "../src/validate.js";

const invalid = (fn: () => unknown) => {
  try {
    fn();
  } catch (e) {
    expect(e).toBeInstanceOf(HttpError);
    expect((e as HttpError).status).toBe(400);
    expect((e as HttpError).reason).toBe("invalid_body");
    return;
  }
  throw new Error("expected a 400");
};

const buy = { side: "buy", asset: "BTC", amount: { usdc: "25.00" } };

describe("parseOrder", () => {
  it("accepts buy, sell units and sell fraction", () => {
    expect(parseOrder({ requestId: "t-1", ...buy })).toEqual({
      requestId: "t-1",
      ...buy,
    });
    const sell = { side: "sell", asset: "ETH", amount: { units: "0.01" } };
    expect(parseOrder({ requestId: "t-2", ...sell }).amount).toEqual({
      units: "0.01",
    });
    const all = { ...sell, amount: { fraction: 1 }, maxSlippageBps: 50 };
    expect(parseOrder({ requestId: "t-3", ...all })).toMatchObject({
      amount: { fraction: 1 },
      maxSlippageBps: 50,
    });
  });

  it("rejects unknown fields and wrong shapes", () => {
    invalid(() => parseOrder({ requestId: "a", ...buy, to: "0x1" }));
    invalid(() => parseOrder({ requestId: "a", ...buy, asset: "SOL" }));
    invalid(() =>
      parseOrder({ requestId: "a", ...buy, amount: { units: "1" } }),
    );
    invalid(() =>
      parseOrder({
        requestId: "a",
        side: "sell",
        asset: "BTC",
        amount: { fraction: 0 },
      }),
    );
    invalid(() =>
      parseOrder({
        requestId: "a",
        side: "sell",
        asset: "BTC",
        amount: { fraction: 1.5 },
      }),
    );
  });

  it("rejects bad decimals, ids and slippage", () => {
    for (const usdc of ["1e3", "-1", "0", "1.", "abc", " 1"]) {
      invalid(() => parseOrder({ requestId: "a", ...buy, amount: { usdc } }));
    }
    invalid(() => parseOrder({ requestId: "has space", ...buy }));
    invalid(() => parseOrder({ requestId: "x".repeat(65), ...buy }));
    for (const b of [0, 1001, 1.5, "50"]) {
      invalid(() => parseOrder({ requestId: "a", ...buy, maxSlippageBps: b }));
    }
    invalid(() => parseOrder(null));
    invalid(() => parseOrder([buy]));
  });
});

describe("other parsers", () => {
  it("parses quotes without a requestId", () => {
    expect(parseQuote(buy)).toEqual(buy);
    invalid(() => parseQuote({ requestId: "a", ...buy }));
  });

  it("parses withdrawals, never with an address", () => {
    expect(
      parseWithdraw({ requestId: "w", asset: "USDC", amount: { all: true } }),
    ).toEqual({ requestId: "w", asset: "USDC", amount: { all: true } });
    expect(
      parseWithdraw({
        requestId: "w",
        asset: "GAS",
        amount: { units: "0.001" },
      }).asset,
    ).toBe("GAS");
    invalid(() =>
      parseWithdraw({
        requestId: "w",
        asset: "USDC",
        amount: { all: true },
        to: "0x1",
      }),
    );
    invalid(() =>
      parseWithdraw({ requestId: "w", asset: "USDC", amount: { all: false } }),
    );
  });

  it("parses approve and halt", () => {
    expect(parseApprove({ asset: "USDC" })).toEqual({ asset: "USDC" });
    invalid(() => parseApprove({ asset: "GAS" }));
    expect(parseHalt({ reason: "manual" })).toEqual({ reason: "manual" });
    invalid(() => parseHalt({ reason: "" }));
  });
});
