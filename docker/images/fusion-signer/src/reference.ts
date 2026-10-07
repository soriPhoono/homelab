/**
 * The independent USD reference price for each asset, from Coinbase's public
 * ticker (the same source the trading strategy uses).
 *
 * Order notional and slippage are always measured against this price, never
 * against 1inch's own quote. If the price cannot be fetched or is not a
 * positive number, the request is refused (fail closed).
 */
import { HttpError } from "./errors.js";
import { COINBASE_PRODUCT, type Asset } from "./tokens.js";

/** The part of a fetch Response this module uses. */
export interface FetchResponse {
  ok: boolean;
  json(): Promise<unknown>;
}

/** Minimal fetch signature, so tests can inject a fake without network. */
export type FetchLike = (
  url: string,
  init: { headers: Record<string, string>; signal: AbortSignal },
) => Promise<FetchResponse>;

/**
 * Returns the current USD price of one whole unit of `asset`. Held by
 * Service as `deps.reference`.
 */
export type Reference = (asset: Asset) => Promise<number>;

/** Refuse the request: 403 `no_reference`. */
const noReference = (): never => {
  throw new HttpError(
    403,
    "no_reference",
    "Coinbase reference price unavailable",
  );
};

/**
 * Create a `Reference` backed by the Coinbase Exchange ticker endpoint.
 *
 * Any failure (network error, timeout after `timeoutMs`, HTTP error, missing,
 * zero or non-numeric price) becomes 403 `no_reference`. main.ts uses the
 * defaults; tests pass a fake `fetchFn`.
 */
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
