import { HttpError } from "./errors.js";
import { COINBASE_PRODUCT, type Asset } from "./tokens.js";

export interface FetchResponse {
  ok: boolean;
  json(): Promise<unknown>;
}

export type FetchLike = (
  url: string,
  init: { headers: Record<string, string>; signal: AbortSignal },
) => Promise<FetchResponse>;

export type Reference = (asset: Asset) => Promise<number>;

const noReference = (): never => {
  throw new HttpError(
    403,
    "no_reference",
    "Coinbase reference price unavailable",
  );
};

export function makeReference(
  fetchFn: FetchLike = fetch as unknown as FetchLike,
  timeoutMs = 5000,
): Reference {
  return async (asset) => {
    const product = COINBASE_PRODUCT[asset];
    const url = `https://api.exchange.coinbase.com/products/${product}/ticker`;
    let body: unknown;
    try {
      const res = await fetchFn(url, {
        headers: { "User-Agent": "fusion-signer" },
        signal: AbortSignal.timeout(timeoutMs),
      });
      if (!res.ok) return noReference();
      body = await res.json();
    } catch {
      return noReference();
    }
    const price = Number((body as { price?: unknown } | null)?.price);
    if (!Number.isFinite(price) || price <= 0) return noReference();
    return price;
  };
}
