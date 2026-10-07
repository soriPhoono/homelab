/**
 * The HTTP edge: routing, bearer-token auth, body parsing, error mapping,
 * secret redaction and one log line per request.
 *
 * Endpoints: GET /health (no auth), GET /status, POST /quote, POST /orders,
 * GET /orders/:hash, POST /approve, POST /withdraw, POST /halt. The server is
 * only reachable on the internal Docker network (no published port), and it
 * is built so that no request, however malformed, can crash the process.
 */
import { createHash, timingSafeEqual } from "node:crypto";
import { createServer, type IncomingMessage, type Server } from "node:http";
import { HttpError, redact, redactDeep } from "./errors.js";
import type { Result, Service } from "./service.js";
import {
  parseApprove,
  parseHalt,
  parseOrder,
  parseQuote,
  parseWithdraw,
} from "./validate.js";

/** Inputs to `buildServer`, supplied by main.ts (or tests). */
export interface ServerOptions {
  /** Handles each endpoint's logic. */
  service: Service;
  /** Bearer token callers must send; at least 32 characters. */
  token: string;
  /** Secret values to scrub from every response body and log line. */
  secrets: string[];
  /** Where log lines go; defaults to one JSON line on stdout. */
  log?: (line: Record<string, unknown>) => void;
}

/** Largest request body accepted (16 KiB); larger bodies get a 413. */
const MAX_BODY = 16 * 1024;

/** A Fusion order hash: 0x followed by 64 hex characters. */
const ORDER_HASH = /^0x[0-9a-fA-F]{64}$/;

/**
 * sha256 of a string. The auth check compares digests rather than raw
 * strings so the comparison is constant-time and length-independent.
 */
const digest = (s: string) => createHash("sha256").update(s).digest();

/**
 * Read the request body and parse it as JSON. An empty body parses as null
 * (which the strict parsers then reject). Too large -> 413, invalid JSON ->
 * 400.
 */
async function readJson(req: IncomingMessage): Promise<unknown> {
  const chunks: Buffer[] = [];
  let size = 0;
  // Drain the whole body even when it is too large, so the client gets
  // the 413 instead of a reset connection.
  for await (const chunk of req) {
    size += (chunk as Buffer).length;
    if (size <= MAX_BODY) chunks.push(chunk as Buffer);
  }
  if (size > MAX_BODY) {
    throw new HttpError(413, "body_too_large", "body over 16 KiB");
  }
  try {
    return JSON.parse(Buffer.concat(chunks).toString("utf8") || "null");
  } catch {
    throw new HttpError(400, "invalid_json", "body is not valid JSON");
  }
}

/**
 * Create (but do not start) the HTTP server; main.ts calls `.listen()`.
 * Throws if the token is shorter than 32 characters.
 */
export function buildServer(opts: ServerOptions): Server {
  if (opts.token.length < 32) {
    throw new Error("token must be at least 32 chars");
  }
  /** Digest of the exact Authorization header a caller must send. */
  const expected = digest(`Bearer ${opts.token}`);
  const log =
    opts.log ??
    ((line: Record<string, unknown>) => console.log(JSON.stringify(line)));
  /** True if the request's Authorization header matches (constant time). */
  const authorized = (req: IncomingMessage) =>
    timingSafeEqual(digest(req.headers.authorization ?? ""), expected);

  /**
   * Dispatch one request to the right Service method. /health is the only
   * route that skips auth. POST bodies go through the strict parsers in
   * validate.ts before the service sees them. Unknown routes are 404.
   */
  const route = async (req: IncomingMessage, path: string) => {
    if (req.method === "GET" && path === "/health") {
      return { status: 200, body: { ok: true } } as Result;
    }
    if (!authorized(req)) {
      throw new HttpError(401, "unauthorized", "bad bearer token");
    }
    const s = opts.service;
    if (req.method === "GET" && path === "/status") return s.status();
    if (req.method === "GET" && path.startsWith("/orders/")) {
      const hash = path.slice("/orders/".length);
      if (!ORDER_HASH.test(hash)) {
        throw new HttpError(400, "invalid_body", "hash must be 0x + 64 hex");
      }
      return s.orderStatus(hash);
    }
    if (req.method === "POST") {
      const handlers: Record<string, (b: unknown) => Promise<Result>> = {
        "/quote": (b) => s.quote(parseQuote(b)),
        "/orders": (b) => s.placeOrder(parseOrder(b)),
        "/approve": (b) => s.approve(parseApprove(b)),
        "/withdraw": (b) => s.withdraw(parseWithdraw(b)),
        "/halt": (b) => s.halt(parseHalt(b)),
      };
      const handler = handlers[path];
      if (handler) return handler(await readJson(req));
    }
    throw new HttpError(404, "not_found", "no such endpoint");
  };

  /**
   * Per-request pipeline, built as one promise chain so nothing throws
   * outside it:
   * 1. Parse the URL (a bad target becomes a 400) and route the request.
   * 2. Map errors: HttpError keeps its status and reason; anything else is
   *    502 with a fixed "upstream error" message, and the real message goes
   *    only to the log (redacted).
   * 3. Redact the body, send it, write one log line.
   * 4. Last resort: if anything above fails (e.g. a body that cannot be
   *    serialized), answer 500 `internal` and log a fixed-shape line.
   */
  const server = createServer((req, res) => {
    const started = Date.now();
    let path = "?";
    let upstreamError: string | undefined;
    const safeLog = (line: Record<string, unknown>) => {
      try {
        log(line);
      } catch {
        // A failing logger must never take the process down.
      }
    };
    Promise.resolve()
      .then(() => {
        try {
          path = new URL(req.url ?? "/", "http://signer").pathname;
        } catch {
          throw new HttpError(400, "invalid_request", "bad request target");
        }
        return route(req, path);
      })
      .catch((err: unknown): Result => {
        if (err instanceof HttpError) {
          return {
            status: err.status,
            body: { error: err.message, reason: err.reason },
          };
        }
        upstreamError = (err as Error)?.message ?? "upstream error";
        return {
          status: 502,
          body: { error: "upstream error", reason: "upstream" },
        };
      })
      .then((result) => {
        const body = redactDeep(result.body, opts.secrets) as Record<
          string,
          unknown
        >;
        const text = JSON.stringify(body);
        res.writeHead(result.status, { "content-type": "application/json" });
        res.end(text);
        safeLog({
          ts: new Date().toISOString(),
          method: req.method,
          path,
          status: result.status,
          reason: body.reason,
          requestId: body.requestId,
          orderHash: body.orderHash,
          error:
            upstreamError === undefined
              ? undefined
              : redact(upstreamError, opts.secrets),
          ms: Date.now() - started,
        });
      })
      .catch(() => {
        if (!res.headersSent) {
          res.writeHead(500, { "content-type": "application/json" });
          res.end('{"error":"internal error","reason":"internal"}');
        } else {
          res.end();
        }
        safeLog({
          ts: new Date().toISOString(),
          method: req.method,
          path,
          status: 500,
          reason: "internal",
        });
      });
  });
  // Drop clients that send headers or bodies too slowly.
  server.requestTimeout = 15_000;
  server.headersTimeout = 10_000;
  return server;
}
