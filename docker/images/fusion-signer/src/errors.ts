/**
 * Error type and secret redaction shared by every layer.
 *
 * Service and guard code throw `HttpError` to refuse a request with a specific
 * status and machine-readable `reason`; the server turns it into the HTTP
 * response. `redact`/`redactDeep` scrub secret values (private key, bearer
 * token, 1inch API key, RPC URL) out of anything that is returned, stored or
 * logged.
 */

/**
 * An error that maps directly to an HTTP response.
 *
 * - `status`: HTTP status code (400 invalid body, 403 guard refusal,
 *   409 request id conflict, 423 halted, 502 upstream failure, ...).
 * - `reason`: stable code callers can branch on (e.g. `order_cap`,
 *   `slippage`, `halted`); also used as the message when none is given.
 *
 * Thrown by validate.ts, guard.ts, reference.ts and service.ts; caught by
 * `Service.once` (which stores refusals) and by the server's error mapping.
 */
export class HttpError extends Error {
  constructor(
    readonly status: number,
    readonly reason: string,
    message?: string,
  ) {
    super(message ?? reason);
  }
}

/**
 * Replace each secret (8+ chars) in `text` with "[redacted]".
 *
 * Exact-substring match only. Shorter strings are skipped so short or empty
 * values cannot blank out unrelated text. Used on error messages before they
 * are stored (service.ts), returned (server.ts) or printed (main.ts,
 * quote-check.ts).
 */
export function redact(text: string, secrets: string[]): string {
  let out = text;
  for (const s of secrets) {
    if (s.length >= 8) out = out.split(s).join("[redacted]");
  }
  return out;
}

/**
 * Copy `value` with every string (recursively) passed through `redact`.
 *
 * The server applies this to every response body before serializing it, so a
 * secret is caught even if it contains characters JSON would escape. Object
 * keys are left as-is; only values are scrubbed.
 */
export function redactDeep(value: unknown, secrets: string[]): unknown {
  if (typeof value === "string") return redact(value, secrets);
  if (Array.isArray(value)) return value.map((v) => redactDeep(v, secrets));
  if (value !== null && typeof value === "object") {
    return Object.fromEntries(
      Object.entries(value).map(([k, v]) => [k, redactDeep(v, secrets)]),
    );
  }
  return value;
}
