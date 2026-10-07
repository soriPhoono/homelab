import { describe, expect, it } from "vitest";
import { assertNotSelf, loadConfig } from "../src/config.js";

// EIP-55 test vector.
const ADDR = "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed";

const SETTLEMENT = "0x1111111254EEB25477B68fb85Ed929f73A960582";

const secrets: Record<string, string> = {
  fusion_signer_key: "0x" + "11".repeat(32) + "\n",
  fusion_signer_token: "t".repeat(64),
  oneinch_api_key: "oneinch-test-key",
  base_rpc_url: "https://base.example/v2/rpc-test-key",
};

const reader =
  (values: Record<string, string>) =>
  (name: string): string => {
    const v = values[name];
    if (v === undefined) throw new Error("ENOENT");
    return v;
  };

const load = (env: Record<string, string>, values = secrets) =>
  loadConfig(
    {
      WITHDRAW_ADDRESS: ADDR,
      FUSION_SETTLEMENT_ADDRESS: SETTLEMENT,
      ...env,
    },
    reader(values),
  );

describe("loadConfig", () => {
  it("applies the spec defaults", () => {
    const c = load({});
    expect(c.dryRun).toBe(true);
    expect(c.limits).toEqual({
      maxOrderUsd: 60,
      maxDailyUsd: 150,
      defaultMaxSlippageBps: 100,
      minOrderIntervalSec: 60,
    });
    expect(c.ethGasReserve).toBe("0.0003");
    expect(c.dataDir).toBe("/data");
    expect(c.port).toBe(8080);
    expect(c.secrets.privateKey).toBe("0x" + "11".repeat(32));
  });

  it("only exactly 'false' turns dry run off", () => {
    expect(load({ DRY_RUN: "False" }).dryRun).toBe(true);
    expect(load({ DRY_RUN: "0" }).dryRun).toBe(true);
    expect(load({ DRY_RUN: "false" }).dryRun).toBe(false);
  });

  it("requires a checksummed withdraw address", () => {
    expect(() => loadConfig({}, reader(secrets))).toThrow(/WITHDRAW_ADDRESS/);
    expect(() => load({ WITHDRAW_ADDRESS: ADDR.toLowerCase() })).toThrow(
      /checksummed/,
    );
    const badSum = "0x5aaeb6053F3E94C9b9A09f33669435E7Ef1BeAed";
    expect(() => load({ WITHDRAW_ADDRESS: badSum })).toThrow(/not a valid/);
  });

  it("requires a checksummed settlement address", () => {
    expect(load({}).settlementAddress).toBe(SETTLEMENT);
    const env = { WITHDRAW_ADDRESS: ADDR };
    expect(() => loadConfig(env, reader(secrets))).toThrow(
      /FUSION_SETTLEMENT_ADDRESS is not a valid/,
    );
    expect(() =>
      load({ FUSION_SETTLEMENT_ADDRESS: SETTLEMENT.toLowerCase() }),
    ).toThrow(/FUSION_SETTLEMENT_ADDRESS must be EIP-55 checksummed/);
  });

  it("names a missing or empty secret without leaking values", () => {
    const missing = { ...secrets };
    delete missing.oneinch_api_key;
    let message = "";
    try {
      load({}, missing);
    } catch (e) {
      message = (e as Error).message;
    }
    expect(message).toBe("secret oneinch_api_key is missing");
    expect(() => load({}, { ...secrets, base_rpc_url: "  \n" })).toThrow(
      "secret base_rpc_url is empty",
    );
  });

  it("rejects a short bearer token and bad limits", () => {
    expect(() =>
      load({}, { ...secrets, fusion_signer_token: "short" }),
    ).toThrow(/fusion_signer_token/);
    expect(() => load({ MAX_ORDER_USD: "0" })).toThrow(/MAX_ORDER_USD/);
    expect(() => load({ MAX_DAILY_USD: "abc" })).toThrow(/MAX_DAILY_USD/);
    expect(() => load({ ETH_GAS_RESERVE: "-1" })).toThrow(/ETH_GAS_RESERVE/);
    expect(() => load({ ETH_GAS_RESERVE: "1e-3" })).toThrow(/ETH_GAS_RESERVE/);
    expect(() => load({ ETH_GAS_RESERVE: "0.0000000000000000001" })).toThrow(
      /ETH_GAS_RESERVE/,
    );
  });

  it("refuses a withdraw address equal to the signer", () => {
    const c = load({});
    expect(() => assertNotSelf(c, ADDR.toLowerCase())).toThrow(/own/);
    const other = "0x0000000000000000000000000000000000000002";
    expect(() => assertNotSelf(c, other)).not.toThrow();
  });
});
