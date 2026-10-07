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

  it("stores a failed submit as 502 with secrets redacted", async () => {
    const { service, fusion } = makeService();
    fusion.failSubmit = true;
    const r = await service.placeOrder(buy("o1"));
    expect(r.status).toBe(502);
    expect(r.body.reason).toBe("upstream");
    expect(JSON.stringify(r.body)).not.toContain(RPC_URL);
    fusion.failSubmit = false;
    expect(await service.placeOrder(buy("o1"))).toEqual(r);
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
});
