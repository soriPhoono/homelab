import { JsonRpcProvider } from "ethers";
import { describe, expect, it, vi } from "vitest";
import { EthersChain } from "../src/adapters/ethers-chain.js";

class Stubbed extends EthersChain {
  oracle: bigint | Error = 0n;
  sizes: bigint[] = [];
  protected override async l1FeeUpperBound(size: bigint): Promise<bigint> {
    this.sizes.push(size);
    if (this.oracle instanceof Error) throw this.oracle;
    return this.oracle;
  }
}

function make() {
  const provider = new JsonRpcProvider("http://127.0.0.1:1", 8453, {
    staticNetwork: true,
  });
  vi.spyOn(provider, "getFeeData").mockResolvedValue({
    maxFeePerGas: 1_000_000n,
  } as never);
  return new Stubbed(provider, "0x" + "22".repeat(32));
}

describe("EthersChain.gasCost", () => {
  it("adds 1.5x the oracle L1 upper bound to the L2 cost", async () => {
    const c = make();
    c.oracle = 4_000_000_000_000n;
    const l2 = (65_000n * 1_000_000n * 12n) / 10n;
    expect(await c.gasCost("erc20")).toBe(l2 + 6_000_000_000_000n);
    expect(c.sizes).toEqual([180n]);
    const l2eth = (21_000n * 1_000_000n * 12n) / 10n;
    expect(await c.gasCost("eth")).toBe(l2eth + 6_000_000_000_000n);
    expect(c.sizes).toEqual([180n, 120n]);
  });

  it("falls back to the fixed margin when the oracle fails", async () => {
    const c = make();
    c.oracle = new Error("call revert");
    const l2 = (65_000n * 1_000_000n * 12n) / 10n;
    expect(await c.gasCost("erc20")).toBe(l2 + 10n ** 13n);
  });
});
