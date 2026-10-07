import { createHash, timingSafeEqual } from "node:crypto";
import { createServer, type IncomingMessage, type Server } from "node:http";
import { HttpError, redact } from "./errors.js";
import type { Result, Service } from "./service.js";
import {
  parseApprove,
  parseHalt,
  parseOrder,
  parseQuote,
  parseWithdraw,
} from "./validate.js";

export interface ServerOptions {
  service: Service;
  token: string;
  secrets: string[];
  log?: (line: Record<string, unknown>) => void;
}

const MAX_BODY = 16 * 1024;
const ORDER_HASH = /^0x[0-9a-fA-F]{64}$/;

const digest = (s: string) => createHash("sha256").update(s).digest();

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

export function buildServer(opts: ServerOptions): Server {
  const expected = digest(`Bearer ${opts.token}`);
  const log =
    opts.log ??
    ((line: Record<string, unknown>) => console.log(JSON.stringify(line)));
  const authorized = (req: IncomingMessage) =>
    timingSafeEqual(digest(req.headers.authorization ?? ""), expected);

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

  return createServer((req, res) => {
    const started = Date.now();
    const path = new URL(req.url ?? "/", "http://signer").pathname;
    route(req, path)
      .catch((err: unknown): Result => {
        if (err instanceof HttpError) {
          return {
            status: err.status,
            body: { error: err.message, reason: err.reason },
          };
        }
        const error = (err as Error)?.message ?? "upstream error";
        return { status: 502, body: { error, reason: "upstream" } };
      })
      .then((result) => {
        const text = redact(JSON.stringify(result.body), opts.secrets);
        res.writeHead(result.status, { "content-type": "application/json" });
        res.end(text);
        const body = result.body;
        const line = JSON.stringify({
          ts: new Date().toISOString(),
          method: req.method,
          path,
          status: result.status,
          reason: body.reason,
          requestId: body.requestId,
          orderHash: body.orderHash,
          ms: Date.now() - started,
        });
        // Redact the serialized line, never the object, so no field can leak.
        log(JSON.parse(redact(line, opts.secrets)) as Record<string, unknown>);
      });
  });
}
