import type { AddressInfo } from "node:net";
import { afterEach, describe, expect, it, vi } from "vitest";
import { HttpError } from "../src/errors.js";
import { buildServer } from "../src/server.js";
import type { Service } from "../src/service.js";

const TOKEN = "t".repeat(64);
const RPC = "https://base.example/v2/rpc-secret-key";
const ok = (body: Record<string, unknown>) => async () => ({
  status: 200,
  body,
});

const service = {
  status: vi.fn(ok({ s: 1 })),
  quote: vi.fn(ok({ q: 1 })),
  placeOrder: vi.fn(ok({ requestId: "r1", orderHash: "0xh" })),
  orderStatus: vi.fn(ok({ o: 1 })),
  approve: vi.fn(ok({ a: 1 })),
  withdraw: vi.fn(ok({ w: 1 })),
  halt: vi.fn(ok({ halted: true })),
};

const lines: Record<string, unknown>[] = [];
let close: () => void = () => {};

async function start() {
  const server = buildServer({
    service: service as unknown as Service,
    token: TOKEN,
    secrets: [RPC, TOKEN],
    log: (l) => lines.push(l),
  });
  await new Promise<void>((r) => server.listen(0, "127.0.0.1", r));
  close = () => server.close();
  const { port } = server.address() as AddressInfo;
  const call = (path: string, init: RequestInit = {}, auth = true) =>
    fetch(`http://127.0.0.1:${port}${path}`, {
      ...init,
      headers: auth ? { authorization: `Bearer ${TOKEN}` } : {},
    });
  return call;
}

afterEach(() => {
  close();
  lines.length = 0;
  vi.clearAllMocks();
});

describe("server", () => {
  it("serves /health without auth and everything else with it", async () => {
    const call = await start();
    expect((await call("/health", {}, false)).status).toBe(200);
    expect((await call("/status", {}, false)).status).toBe(401);
    const wrong = await fetch(new URL("/status", (await call("/health")).url), {
      headers: { authorization: "Bearer nope" },
    });
    expect(wrong.status).toBe(401);
    expect((await call("/status")).status).toBe(200);
  });

  it("routes POST bodies through the strict parsers", async () => {
    const call = await start();
    const post = (path: string, body: string) =>
      call(path, { method: "POST", body });
    const order = {
      requestId: "r1",
      side: "buy",
      asset: "BTC",
      amount: { usdc: "5" },
    };
    expect((await post("/orders", JSON.stringify(order))).status).toBe(200);
    expect(service.placeOrder).toHaveBeenCalledWith(order);
    const extra = JSON.stringify({ ...order, to: "0x1" });
    const r = await post("/orders", extra);
    expect(r.status).toBe(400);
    expect(((await r.json()) as { reason: string }).reason).toBe(
      "invalid_body",
    );
    expect((await post("/orders", "{not json")).status).toBe(400);
    expect((await post("/halt", "x".repeat(17_000))).status).toBe(413);
  });

  it("validates order hashes and unknown paths", async () => {
    const call = await start();
    expect((await call("/orders/abc")).status).toBe(400);
    expect((await call(`/orders/0x${"ab".repeat(32)}`)).status).toBe(200);
    expect((await call("/nope")).status).toBe(404);
  });

  it("maps errors and redacts secrets in replies and logs", async () => {
    const call = await start();
    service.status.mockRejectedValueOnce(new Error(`fetch ${RPC} failed`));
    const r = await call("/status");
    expect(r.status).toBe(502);
    const text = await r.text();
    expect(text).toContain("[redacted]");
    expect(text).not.toContain(RPC);
    service.status.mockRejectedValueOnce(new HttpError(423, "halted"));
    expect((await call("/status")).status).toBe(423);
    expect(JSON.stringify(lines)).not.toContain(RPC);
    expect(JSON.stringify(lines)).not.toContain(TOKEN);
  });

  it("logs one line per request", async () => {
    const call = await start();
    await call("/orders", {
      method: "POST",
      body: JSON.stringify({
        requestId: "r1",
        side: "buy",
        asset: "BTC",
        amount: { usdc: "5" },
      }),
    });
    expect(lines).toHaveLength(1);
    expect(lines[0]).toMatchObject({
      method: "POST",
      path: "/orders",
      status: 200,
      requestId: "r1",
      orderHash: "0xh",
    });
  });
});
