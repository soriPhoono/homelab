import { describe, expect, it } from "vitest";
import { LOP_V4, TOKENS } from "../src/tokens.js";
import { METAMASK, RPC_URL, SIGNER, makeService, testConfig } from "./fakes.js";

describe("status and quote", () => {
  it("reports balances, limits and flags", async () => {
    const { service, deps } = makeService();
    deps.store.halt("x");
    const r = await service.status();
    expect(r.body).toMatchObject({
      address: SIGNER,
      chainId: 8453,
      dryRun: false,
      halted: true,
      withdrawAddress: METAMASK,
      balances: { USDC: "100.0", BTC: "0.0", ETH: "0.0", GAS: "0.01" },
      allowances: { USDC: "150.0" },
    });
    expect(r.body.limits).toEqual(deps.config.limits);
  });

  it("quotes start and worst prices against Coinbase", async () => {
    const { service } = makeService();
    const r = await service.quote({
      side: "buy",
      asset: "BTC",
      amount: { usdc: "50" },
    });
    expect(r.body.refPrice).toBe(100_000);
    expect(r.body.slippageBps as number).toBeCloseTo(20, 0);
    expect(r.body.worstPrice as number).toBeGreaterThan(100_000);
  });
});

describe("orderStatus", () => {
  it("sums fills, including partial and expired orders", async () => {
    const { service, fusion } = makeService();
    for (const status of ["filled", "partially-filled", "expired"]) {
      fusion.nextStatus = {
        status,
        makerAsset: TOKENS.USDC.address.toLowerCase(),
        takerAsset: TOKENS.BTC.address.toLowerCase(),
        fills: [
          { txHash: "0x1", makerAmount: 20_000_000n, takerAmount: 20_000n },
          { txHash: "0x2", makerAmount: 5_000_000n, takerAmount: 5_000n },
        ],
      };
      const r = await service.orderStatus("0x" + "cd".repeat(32));
      expect(r.body).toMatchObject({
        status,
        sellToken: "USDC",
        soldAmount: "25.0",
        buyToken: "cbBTC",
        boughtAmount: "0.00025",
      });
      expect(r.body.effectivePrice as number).toBeCloseTo(100_000, 6);
    }
  });

  it("reports no price before any fill", async () => {
    const { service, fusion } = makeService();
    fusion.nextStatus = {
      status: "pending",
      makerAsset: TOKENS.BTC.address,
      takerAsset: TOKENS.USDC.address,
      fills: [],
    };
    const r = await service.orderStatus("0x" + "cd".repeat(32));
    expect(r.body).toMatchObject({ status: "pending", effectivePrice: null });
  });
});

describe("approve", () => {
  it("approves at most the daily cap's worth", async () => {
    const { service, chain } = makeService();
    const r = await service.approve({ asset: "BTC" });
    expect(r.body).toMatchObject({ status: "sent", amount: "0.0015" });
    expect(chain.sent).toEqual([
      {
        kind: "approve",
        token: TOKENS.BTC.address,
        to: LOP_V4,
        amount: 150_000n,
      },
    ]);
  });

  it("floors to the cap for non-terminating prices", async () => {
    const exact = makeService({ reference: async () => 3 });
    await exact.service.approve({ asset: "ETH" });
    expect(exact.chain.sent[0]?.amount).toBe(50n * 10n ** 18n);
    const { service, chain } = makeService({ reference: async () => 7 });
    await service.approve({ asset: "ETH" });
    expect(chain.sent[0]?.amount).toBe(
      (150_000_000n * 10n ** 18n) / 7_000_000n,
    );
  });

  it("refuses while halted", async () => {
    const { service, chain, deps } = makeService();
    deps.store.halt("x");
    await expect(service.approve({ asset: "USDC" })).rejects.toMatchObject({
      status: 423,
      reason: "halted",
    });
    expect(chain.sent).toEqual([]);
  });

  it("dry run approves nothing", async () => {
    const config = testConfig({ dryRun: true });
    const { service, chain } = makeService({ config });
    const r = await service.approve({ asset: "USDC" });
    expect(r.body).toMatchObject({ status: "dry_run", amount: "150.0" });
    expect(chain.sent).toEqual([]);
  });
});

describe("withdraw", () => {
  it("always sends to the configured MetaMask address", async () => {
    const { service, chain } = makeService();
    const r = await service.withdraw({
      requestId: "w1",
      asset: "USDC",
      amount: { all: true },
    });
    expect(r.body).toMatchObject({ status: "sent", to: METAMASK });
    expect(chain.sent).toEqual([
      {
        kind: "transfer",
        token: TOKENS.USDC.address,
        to: METAMASK,
        amount: 100_000_000n,
      },
    ]);
  });

  it("keeps gas for a partial ETH withdrawal", async () => {
    const { service } = makeService();
    const r = await service.withdraw({
      requestId: "w2",
      asset: "GAS",
      amount: { units: "0.0098" },
    });
    expect(r.body.reason).toBe("gas_reserve");
  });

  it("keeps gas for the transfer itself on a partial ETH withdrawal", async () => {
    const config = testConfig({ ethGasReserve: "0.0000001" });
    const { service, chain } = makeService({ config });
    const r = await service.withdraw({
      requestId: "w9",
      asset: "GAS",
      amount: { units: "0.0099995" },
    });
    expect(r.body.reason).toBe("no_gas");
    expect(chain.sent).toEqual([]);
  });

  it("withdraws all ETH minus the transfer's gas", async () => {
    const { service, chain } = makeService();
    await service.withdraw({
      requestId: "w3",
      asset: "GAS",
      amount: { all: true },
    });
    expect(chain.sent[0]).toEqual({
      kind: "eth",
      to: METAMASK,
      amount: 10n ** 16n - 10n ** 12n,
    });
  });

  it("refuses without gas or balance", async () => {
    const { service, chain } = makeService();
    chain.eth = 0n;
    const noGas = await service.withdraw({
      requestId: "w4",
      asset: "USDC",
      amount: { units: "1" },
    });
    expect(noGas.body.reason).toBe("no_gas");
    const empty = await service.withdraw({
      requestId: "w5",
      asset: "BTC",
      amount: { all: true },
    });
    expect(empty.body.reason).toBe("insufficient_balance");
  });

  it("works while halted and in dry run sends nothing", async () => {
    const config = testConfig({ dryRun: true });
    const { service, chain, deps } = makeService({ config });
    deps.store.halt("emergency");
    const r = await service.withdraw({
      requestId: "w6",
      asset: "USDC",
      amount: { units: "10" },
    });
    expect(r.body).toMatchObject({ status: "dry_run", amount: "10.0" });
    expect(chain.sent).toEqual([]);
  });

  it("is not blocked by an order that is still building", async () => {
    const { service, fusion } = makeService();
    let open!: () => void;
    fusion.gate = new Promise((r) => (open = r));
    const order = service.placeOrder({
      requestId: "q1",
      side: "buy",
      asset: "BTC",
      amount: { usdc: "25" },
    });
    const r = await service.withdraw({
      requestId: "wq",
      asset: "USDC",
      amount: { units: "10" },
    });
    expect(r.body.status).toBe("sent");
    open();
    expect((await order).body.status).toBe("pending");
  });

  it("stores a failed send so a retry never sends twice", async () => {
    const { service, chain } = makeService();
    chain.failSend = true;
    const req = {
      requestId: "w7",
      asset: "USDC" as const,
      amount: { units: "10" },
    };
    const r = await service.withdraw(req);
    expect(r.status).toBe(502);
    expect(JSON.stringify(r.body)).not.toContain(RPC_URL);
    chain.failSend = false;
    expect(await service.withdraw(req)).toEqual(r);
    expect(chain.sent).toEqual([]);
  });

  it("leaves an intent marker that a retry replays as 202", async () => {
    const { service, chain, deps } = makeService();
    const real = deps.store.putRequest.bind(deps.store);
    let calls = 0;
    deps.store.putRequest = (id, result) => {
      calls += 1;
      if (calls === 2) throw new Error("disk full");
      real(id, result);
    };
    const req = {
      requestId: "w8",
      asset: "USDC" as const,
      amount: { units: "10" },
    };
    await expect(service.withdraw(req)).rejects.toThrow("disk full");
    expect(chain.sent).toHaveLength(1);
    deps.store.putRequest = real;
    const again = await service.withdraw(req);
    expect(again.status).toBe(202);
    expect(again.body.status).toBe("sending");
    expect(chain.sent).toHaveLength(1);
  });
});

describe("halt", () => {
  it("halts the store", async () => {
    const { service, deps } = makeService();
    expect((await service.halt({ reason: "manual" })).body).toEqual({
      halted: true,
    });
    expect(deps.store.isHalted()).toBe(true);
  });
});
