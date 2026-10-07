import { existsSync, mkdtempSync, readdirSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { afterEach, describe, expect, it } from "vitest";
import { Store } from "../src/state.js";

const dirs: string[] = [];
const tempDir = () => {
  const d = mkdtempSync(join(tmpdir(), "fusion-signer-"));
  dirs.push(d);
  return d;
};
afterEach(() => dirs.splice(0).forEach((d) => rmSync(d, { recursive: true })));

describe("Store", () => {
  it("persists requests and order times across instances", () => {
    const dir = tempDir();
    const a = new Store(dir);
    a.putRequest("r1", { bodyHash: "h", status: 200, body: { ok: 1 } });
    a.setLastOrderAt("BTC", 1234);
    const b = new Store(dir);
    expect(b.getRequest("r1")).toEqual({
      bodyHash: "h",
      status: 200,
      body: { ok: 1 },
    });
    expect(b.lastOrderAt("BTC")).toBe(1234);
    expect(b.lastOrderAt("ETH")).toBeUndefined();
  });

  it("resets the daily total at UTC midnight", () => {
    let t = Date.UTC(2026, 9, 7, 23, 59);
    const s = new Store(tempDir(), () => t);
    s.addDailyUsd(50);
    s.addDailyUsd(25);
    expect(s.dailyUsd()).toBe(75);
    t = Date.UTC(2026, 9, 8, 0, 0);
    expect(s.dailyUsd()).toBe(0);
  });

  it("halts through a file only the user removes", () => {
    const dir = tempDir();
    new Store(dir).halt("test");
    expect(new Store(dir).isHalted()).toBe(true);
    rmSync(join(dir, "halt"));
    expect(new Store(dir).isHalted()).toBe(false);
  });

  it("writes atomically and leaves no temp file", () => {
    const dir = tempDir();
    new Store(dir).addDailyUsd(1);
    expect(readdirSync(dir)).toEqual(["state.json"]);
    expect(existsSync(join(dir, "state.json.tmp"))).toBe(false);
  });
});
