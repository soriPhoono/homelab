export class HttpError extends Error {
  constructor(
    readonly status: number,
    readonly reason: string,
    message?: string,
  ) {
    super(message ?? reason);
  }
}

/** Replace each secret (8+ chars) in `text` with "[redacted]". */
export function redact(text: string, secrets: string[]): string {
  let out = text;
  for (const s of secrets) {
    if (s.length >= 8) out = out.split(s).join("[redacted]");
  }
  return out;
}

/** Copy `value` with every string (recursively) passed through `redact`. */
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
