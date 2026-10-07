import { readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";
import { HttpError } from "../src/errors.js";
import { TOKENS } from "../src/tokens.js";
import type { OrderRequest } from "../src/validate.js";
import { RPC_URL, makeService, testConfig } from "./fakes.js";

const buy = (requestId: string, usdc = "25.00"): OrderRequest => ({
  requestId,
  side: "buy",
  asset: "BTC",
  amount: { usdc },
});

const thrown = async (p: Promise<unknown>) =>
  (await p.catch((e: unknown) => e)) as HttpError;

describe("placeOrder", () => {
  it("dry run signs nothing and counts nothing", async () => {
    const config = testConfig({ dryRun: true });
    const { service, fusion, deps } = makeService({ config });
    const r = await service.placeOrder(buy("d1"));
    expect(r.status).toBe(200);
    expect(r.body).toMatchObject({ status: "dry_run", sellToken: "USDC" });
    expect(fusion.submits).toBe(0);
    expect(deps.store.dailyUsd()).toBe(0);
  });

  it("submits once, counts notional and returns the hash", async () => {
    const { service, fusion, deps } = makeService();
    const r = await service.placeOrder(buy("o1"));
    expect(r.body).toMatchObject({
      status: "pending",
      orderHash: "0x" + "cd".repeat(32),
      notionalUsd: 25,
    });
    expect(fusion.submits).toBe(1);
    expect(deps.store.dailyUsd()).toBe(25);
    expect(deps.store.lastOrderAt("BTC")).toBe(deps.now());
  });

  it("replays a repeated requestId without resubmitting", async () => {
    const { service, fusion } = makeService();
    const first = await service.placeOrder(buy("o1"));
    const again = await service.placeOrder(buy("o1"));
    expect(again).toEqual(first);
    expect(fusion.submits).toBe(1);
  });

  it("rejects a reused requestId with a different body", async () => {
    const { service } = makeService();
    await service.placeOrder(buy("o1"));
    const e = await thrown(service.placeOrder(buy("o1", "26.00")));
    expect([e.status, e.reason]).toEqual([409, "request_id_conflict"]);
  });

  it("refuses a concurrent retry of an in-flight request", async () => {
    const { service, fusion } = makeService();
    let open!: () => void;
    fusion.gate = new Promise((r) => (open = r));
    const first = service.placeOrder(buy("o1"));
    const e = await thrown(service.placeOrder(buy("o1")));
    expect([e.status, e.reason]).toEqual([409, "request_in_progress"]);
    open();
    await first;
    expect(fusion.submits).toBe(1);
  });

  it("refuses everything while halted", async () => {
    const { service, fusion, deps } = makeService();
    deps.store.halt("test");
    const e = await thrown(service.placeOrder(buy("o1")));
    expect([e.status, e.reason]).toEqual([423, "halted"]);
    expect(fusion.submits).toBe(0);
  });

  it("stores refusals so a replay returns the same 403", async () => {
    const { service } = makeService();
    const r = await service.placeOrder(buy("big", "61.00"));
    expect(r.status).toBe(403);
    expect(r.body.reason).toBe("order_cap");
    expect(await service.placeOrder(buy("big", "61.00"))).toEqual(r);
  });

  it("enforces spacing per asset", async () => {
    const { service, advance } = makeService();
    await service.placeOrder(buy("o1"));
    const r = await service.placeOrder(buy("o2"));
    expect(r.body.reason).toBe("too_soon");
    advance(60_000);
    expect((await service.placeOrder(buy("o3"))).body.status).toBe("pending");
  });

  it("refuses a full sell of an empty balance", async () => {
    const { service, fusion } = makeService();
    const r = await service.placeOrder({
      requestId: "s1",
      side: "sell",
      asset: "BTC",
      amount: { fraction: 1 },
    });
    expect(r.body.reason).toBe("insufficient_balance");
    expect(fusion.submits).toBe(0);
  });

  it("sells a fraction of the balance", async () => {
    const { service, chain } = makeService();
    chain.balances.set(TOKENS.BTC.address, 40_000n);
    chain.allowances.set(TOKENS.BTC.address, 10n ** 8n);
    const r = await service.placeOrder({
      requestId: "s2",
      side: "sell",
      asset: "BTC",
      amount: { fraction: 0.5 },
    });
    expect(r.body).toMatchObject({ status: "pending", sellAmount: "0.0002" });
  });

  it("refuses a tampered receiver", async () => {
    const { service, fusion } = makeService();
    fusion.receiver = "0x00000000000000000000000000000000000000B2";
    const r = await service.placeOrder(buy("o1"));
    expect(r.body.reason).toBe("order_mismatch");
    expect(fusion.submits).toBe(0);
  });

  it("refuses an order bound to another settlement contract", async () => {
    const { service, fusion } = makeService();
    fusion.settlement = "0x00000000000000000000000000000000000000B2";
    const r = await service.placeOrder(buy("o1"));
    expect(r.body.reason).toBe("order_mismatch");
    expect(fusion.submits).toBe(0);
  });

  it("rechecks the halt flag after the build, inside the queue", async () => {
    const { service, fusion, deps } = makeService();
    let open!: () => void;
    fusion.gate = new Promise((r) => (open = r));
    const pending = service.placeOrder(buy("h1"));
    deps.store.halt("during build");
    open();
    const r = await pending;
    expect([r.status, r.body.reason]).toEqual([423, "halted"]);
    expect(fusion.submits).toBe(0);
    expect(deps.store.dailyUsd()).toBe(0);
    expect(deps.store.lastOrderAt("BTC")).toBeUndefined();
  });

  it("turns a hung upstream into a stored 502", async () => {
    const { service, fusion } = makeService({ upstreamTimeoutMs: 50 });
    fusion.hang = true;
    const r = await service.placeOrder(buy("t1"));
    expect([r.status, r.body.reason]).toEqual([502, "upstream"]);
    expect(r.body.error).toBe("build order timed out");
    expect(fusion.submits).toBe(0);
    expect(await service.placeOrder(buy("t1"))).toEqual(r);
  });

  it("carries the order hash in every outcome that built one", async () => {
    const hash = "0x" + "cd".repeat(32);
    const dry = makeService({ config: testConfig({ dryRun: true }) });
    expect((await dry.service.placeOrder(buy("d1"))).body.orderHash).toBe(hash);
    const live = makeService();
    const r = await live.service.placeOrder(buy("p1"));
    expect(r.body.orderHash).toBe(hash);
    const marker = live.deps.store.getRequest("p1");
    expect(marker?.body).toMatchObject({ orderHash: hash });
  });

  it("keeps the intent marker's order hash while submitting", async () => {
    const { service, fusion, deps } = makeService();
    const submit = fusion.build.bind(fusion);
    let seen: unknown;
    fusion.build = async (...a) => {
      const b = await submit(...a);
      const send = b.submit;
      b.submit = async () => {
        seen = deps.store.getRequest("m1")?.body;
        return send();
      };
      return b;
    };
    await service.placeOrder(buy("m1"));
    expect(seen).toMatchObject({
      status: "submitting",
      orderHash: "0x" + "cd".repeat(32),
    });
  });

  it("refuses a slippage request looser than the configured limit", async () => {
    const { service, fusion } = makeService();
    const req = { ...buy("sl1"), maxSlippageBps: 101 };
    const e = await thrown(service.placeOrder(req));
    expect([e.status, e.reason]).toEqual([400, "invalid_body"]);
    expect(e.message).toBe("maxSlippageBps above the configured limit");
    expect(fusion.submits).toBe(0);
    const ok = await service.placeOrder({ ...buy("sl2"), maxSlippageBps: 100 });
    expect(ok.body.status).toBe("pending");
  });

  it("stores a failed submit as 502 with secrets redacted", async () => {
    const { service, fusion, deps } = makeService();
    fusion.failSubmit = true;
    const r = await service.placeOrder(buy("o1"));
    expect(r.status).toBe(502);
    expect(r.body.reason).toBe("upstream");
    expect(r.body.orderHash).toBe("0x" + "cd".repeat(32));
    expect(JSON.stringify(r.body)).not.toContain(RPC_URL);
    expect(deps.store.getRequest("o1")?.body).toEqual(r.body);
    fusion.failSubmit = false;
    expect(await service.placeOrder(buy("o1"))).toEqual(r);
    expect(deps.store.dailyUsd()).toBe(25);
    expect(fusion.submits).toBe(0);
  });

  it("stores a missing reference price as 403", async () => {
    const { service } = makeService({
      reference: async () => {
        throw new HttpError(403, "no_reference");
      },
    });
    const r = await service.placeOrder(buy("o1"));
    expect(r.body.reason).toBe("no_reference");
  });

  it("rejects more decimals than the token has with a 400", async () => {
    const { service } = makeService();
    const e = await thrown(service.placeOrder(buy("o1", "1.0000001")));
    expect([e.status, e.reason]).toEqual([400, "invalid_body"]);
  });

  it("leaves an intent marker that a retry replays as 202", async () => {
    const { service, fusion, deps } = makeService();
    const real = deps.store.putRequest.bind(deps.store);
    let calls = 0;
    deps.store.putRequest = (id, result) => {
      calls += 1;
      if (calls === 2) throw new Error("disk full");
      real(id, result);
    };
    await expect(service.placeOrder(buy("o1"))).rejects.toThrow("disk full");
    expect(fusion.submits).toBe(1);
    deps.store.putRequest = real;
    const again = await service.placeOrder(buy("o1"));
    expect(again.status).toBe(202);
    expect(again.body.status).toBe("submitting");
    expect(fusion.submits).toBe(1);
  });

  it("serializes orders so the daily cap holds under concurrency", async () => {
    const { service, deps, chain } = makeService();
    chain.balances.set(TOKENS.USDC.address, 1_000_000_000n);
    chain.allowances.set(TOKENS.USDC.address, 1_000_000_000n);
    deps.store.addDailyUsd(100);
    const eth: OrderRequest = {
      requestId: "b",
      side: "buy",
      asset: "ETH",
      amount: { usdc: "30.00" },
    };
    const rs = await Promise.all([
      service.placeOrder(buy("a", "30.00")),
      service.placeOrder(eth),
    ]);
    expect(rs.map((r) => r.body.status ?? r.body.reason).sort()).toEqual([
      "daily_cap",
      "pending",
    ]);
  });

  it("serializes same-asset orders so spacing holds", async () => {
    const { service } = makeService();
    const rs = await Promise.all([
      service.placeOrder(buy("a")),
      service.placeOrder(buy("b")),
    ]);
    expect(rs.map((r) => r.body.status ?? r.body.reason).sort()).toEqual([
      "pending",
      "too_soon",
    ]);
  });

  it("records a non-HttpError as a redacted 502", async () => {
    const config = testConfig();
    const { service } = makeService({
      config,
      reference: async () => {
        throw new Error(`fetch ${RPC_URL} failed`);
      },
    });
    const r = await service.placeOrder(buy("o1"));
    expect(r.status).toBe(502);
    expect(r.body.reason).toBe("upstream");
    expect(JSON.stringify(r.body)).not.toContain(RPC_URL);
    expect(await service.placeOrder(buy("o1"))).toEqual(r);
    const file = readFileSync(join(config.dataDir, "state.json"), "utf8");
    expect(file).not.toContain(RPC_URL);
  });
});
