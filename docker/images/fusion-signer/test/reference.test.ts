import { describe, expect, it } from "vitest";
import { HttpError } from "../src/errors.js";
import { makeReference, type FetchLike } from "../src/reference.js";

const reply =
  (ok: boolean, body: unknown): FetchLike =>
  async () => ({ ok, json: async () => body });

const noRef = async (p: Promise<number>) => {
  const e = await p.catch((err: unknown) => err);
  expect(e).toBeInstanceOf(HttpError);
  expect((e as HttpError).status).toBe(403);
  expect((e as HttpError).reason).toBe("no_reference");
};

describe("makeReference", () => {
  it("returns the Coinbase ticker price for the asset", async () => {
    const urls: string[] = [];
    const fetchFn: FetchLike = async (url) => {
      urls.push(url);
      return { ok: true, json: async () => ({ price: "85000.5" }) };
    };
    expect(await makeReference(fetchFn)("BTC")).toBe(85000.5);
    expect(urls[0]).toBe(
      "https://api.exchange.coinbase.com/products/BTC-USD/ticker",
    );
  });

  it("refuses on HTTP errors, throws and bad prices", async () => {
    await noRef(makeReference(reply(false, {}))("ETH"));
    const boom: FetchLike = async () => {
      throw new Error("network down");
    };
    await noRef(makeReference(boom)("ETH"));
    await noRef(makeReference(reply(true, { price: "0" }))("ETH"));
    await noRef(makeReference(reply(true, {}))("ETH"));
    await noRef(makeReference(reply(true, null))("ETH"));
  });
});
