import { describe, expect, it } from "vitest";
import { redact } from "../src/errors.js";
import { TOKENS, fromRaw, toRaw, tokenByAddress } from "../src/tokens.js";

describe("tokens", () => {
  it("parses amounts at each token's decimals", () => {
    expect(toRaw("25.00", TOKENS.USDC.decimals)).toBe(25_000_000n);
    expect(toRaw("0.000291", TOKENS.BTC.decimals)).toBe(29_100n);
    expect(toRaw("1", TOKENS.ETH.decimals)).toBe(10n ** 18n);
  });

  it("formats raw amounts back to decimals", () => {
    expect(fromRaw(29_100n, 8)).toBe("0.000291");
    expect(fromRaw(1n, 18)).toBe("0.000000000000000001");
  });

  it("rejects more decimals than the token has", () => {
    expect(() => toRaw("0.0000001", 6)).toThrow();
  });

  it("finds tokens by address in any case", () => {
    const lower = TOKENS.BTC.address.toLowerCase();
    expect(tokenByAddress(lower)?.key).toBe("BTC");
    const unknown = "0x0000000000000000000000000000000000000001";
    expect(tokenByAddress(unknown)).toBeUndefined();
  });
});

describe("redact", () => {
  it("replaces every secret of 8+ chars", () => {
    const url = "https://base.example/v2/abcdef123456";
    const text = `connect ${url} failed; again ${url}`;
    expect(redact(text, [url, "short"])).toBe(
      "connect [redacted] failed; again [redacted]",
    );
  });
});
