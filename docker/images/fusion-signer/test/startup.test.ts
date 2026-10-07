import { getAddress } from "ethers";
import { describe, expect, it } from "vitest";
import { startupChecks } from "../src/startup.js";
import { TOKENS } from "../src/tokens.js";
import { FakeChain, testConfig } from "./fakes.js";

describe("startupChecks", () => {
  it("passes on Base with the expected decimals", async () => {
    await expect(
      startupChecks(new FakeChain(), testConfig()),
    ).resolves.toBeUndefined();
  });

  it("refuses another chain", async () => {
    const chain = new FakeChain();
    chain.chainId = async () => 1;
    await expect(startupChecks(chain, testConfig())).rejects.toThrow(
      /expected Base/,
    );
  });

  it("refuses unexpected token decimals", async () => {
    const chain = new FakeChain();
    chain.decimals = async (t: string) => (t === TOKENS.BTC.address ? 18 : 6);
    await expect(startupChecks(chain, testConfig())).rejects.toThrow(
      /cbBTC has 18 decimals/,
    );
  });

  it("refuses a withdraw address equal to the signer", async () => {
    const chain = new FakeChain();
    // Config holds the checksummed form, as loadConfig requires.
    const withdrawAddress = getAddress(chain.address);
    const config = testConfig({ withdrawAddress });
    await expect(startupChecks(chain, config)).rejects.toThrow(/own/);
  });
});
