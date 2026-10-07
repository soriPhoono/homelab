# Fusion Signer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `fusion-signer`, a guarded 1inch Fusion signer on Base that
runs in the n8n Swarm stack, plus the n8n objects that test it and withdraw
from it.

**Architecture:** A small TypeScript HTTP service. Pure modules (config,
validation, guard, state) sit behind two ports, `Chain` (ethers) and `Fusion`
(1inch SDK), so every rule is unit-tested with fakes. The real adapters are
thin and verified against live Base in a dry run. The image is built by a
GitHub workflow and deployed by Swarm-CD with SOPS-backed Swarm secrets.

**Tech Stack:** Node 22, TypeScript (NodeNext ESM), `@1inch/fusion-sdk`,
`ethers` v6, vitest, pnpm, Docker, GitHub Actions, Swarm-CD, SOPS/age, n8n.

**Spec:** `docs/superpowers/specs/2026-10-07-fusion-signer-design.md`

## Global Constraints

- Work on branch `feat/fusion-signer` in `~/Projects/homelab`. One logical
  change per commit, conventional commit messages, each ending with the
  attribution lines below.
- Commit trailer, verbatim:
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and
  `Claude-Session: https://claude.ai/code/session_01MMc8APpu3V7huGem8Z95Dj`.
- Pre-commit runs treefmt (prettier), markdownlint (80 columns, also inside
  code blocks), gitleaks, actionlint, editorconfig and commitizen. If treefmt
  rewrites a file, `git add` it again and re-run the same commit.
- Never commit a secret value. Secrets live only in SOPS files under
  `docker/stacks/n8n/secrets/`, created by the user.
- Never deploy. Do not push unless the user asks. Swarm-CD deploys `main`.
- Service directory: `docker/images/fusion-signer/`. All `pnpm` commands run
  there through `nix shell nixpkgs#nodejs_22 nixpkgs#pnpm -c pnpm ...`.
- Chain: Base, chain id `8453`. Tokens and approval target, hardcoded:
  USDC `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` (6),
  cbBTC `0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf` (8),
  WETH `0x4200000000000000000000000000000000000006` (18),
  1inch LOP v4 `0x111111125421cA6dc452d289314280a0f8842A65`.
- Limits and defaults: `DRY_RUN=true` unless exactly `false`;
  `MAX_ORDER_USD=60`; `MAX_DAILY_USD=150`; `DEFAULT_MAX_SLIPPAGE_BPS=100`;
  `MIN_ORDER_INTERVAL_SEC=60`; `ETH_GAS_RESERVE=0.0003`; `WITHDRAW_ADDRESS`
  required, EIP-55 checksummed, not the signer's own address.
- Secret names (Swarm secret / file): `fusion_signer_key` /
  `fusion-signer-key`, `fusion_signer_token` / `fusion-signer-token`,
  `oneinch_api_key` / `oneinch-api-key`, `base_rpc_url` / `base-rpc-url`.
- SOPS recipients for stack secrets (public keys):
  `age1y4x8gzzcdhxvqaf9matt0eze3z3yxwx607avq4cexfkgwal4psesj39lvn` (user)
  and `age1t405nrcjuavjg3u3qk65q2vnwkdm9zrc5j04xdk5kwl39kcucp5sscq8z6` (VPS).
- Profit sweep defaults (n8n, later workflow): `SWEEP_SHARE=0.2`,
  `MIN_SWEEP_USD=1`.

## Review Focus

- **Two n8n retries of the same order arrive while the first is still in
  flight.** Expect exactly one submit; the second gets 409
  `request_in_progress`. Test in Task 7.
- **An upstream error message contains the RPC URL (it embeds a provider
  key).** Expect `[redacted]` in the HTTP response, the stored result and the
  log line. Tests in Tasks 1, 7 and 9.
- **A sell with `{ "fraction": 1 }` when the balance is zero.** Expect 403
  `insufficient_balance`, never a zero-amount order. Test in Task 7.
- **An order ends `partially-filled` or `expired` after some fills.** Expect
  sold and bought totals and the effective price from the fills that
  happened. Test in Task 8.
- **A withdraw transaction fails after it may have been broadcast.** Expect
  502 stored under the `requestId`, so a retry returns the stored result and
  never sends twice. Test in Task 8.

## File map

```text
docker/images/fusion-signer/
  package.json, pnpm-lock.yaml, tsconfig.json, tsconfig.build.json
  .gitignore, .dockerignore, Dockerfile
  src/errors.ts         HttpError, redact()
  src/tokens.ts         chain constants, TOKENS, unit conversion
  src/version.ts        VERSION read from package.json
  src/config.ts         env + secret loading and validation
  src/state.ts          Store: requests, daily notional, halt (in /data)
  src/validate.ts       strict request parsing (400 on anything unknown)
  src/reference.ts      Coinbase reference price
  src/ports.ts          Chain and Fusion interfaces
  src/guard.ts          pure limit, mismatch and slippage checks
  src/service.ts        orchestration, idempotency, dry run
  src/server.ts         HTTP routing, auth, logging
  src/startup.ts        chain id, decimals, withdraw address checks
  src/adapters/ethers-chain.ts   Chain over ethers v6
  src/adapters/fusion-client.ts  Fusion over @1inch/fusion-sdk
  src/main.ts           wiring
  src/quote-check.ts    layer-2 dry-run quote probe
  test/*.test.ts, test/fakes.ts
  scripts/seal-secret.sh, scripts/new-wallet.sh
.github/workflows/fusion-signer-image.yml
docker/stacks/n8n/docker-compose.yml   (modified)
docker/stacks/n8n/README.md            (modified)
```

---

### Task 1: Package scaffold, tokens and errors

**Files:**

- Create: `docker/images/fusion-signer/package.json`
- Create: `docker/images/fusion-signer/tsconfig.json`
- Create: `docker/images/fusion-signer/tsconfig.build.json`
- Create: `docker/images/fusion-signer/.gitignore`
- Create: `docker/images/fusion-signer/.dockerignore`
- Create: `docker/images/fusion-signer/src/errors.ts`
- Create: `docker/images/fusion-signer/src/tokens.ts`
- Create: `docker/images/fusion-signer/src/version.ts`
- Test: `docker/images/fusion-signer/test/tokens.test.ts`

**Interfaces:**

- Produces: `class HttpError(status: number, reason: string, message?)`;
  `redact(text: string, secrets: string[]): string`;
  `type Asset = "BTC" | "ETH"`; `type TokenKey = "USDC" | Asset`;
  `type Holding = TokenKey | "GAS"`;
  `interface Token { key; symbol; address; decimals }`; `CHAIN_ID`;
  `LOP_V4`; `TOKENS: Record<TokenKey, Token>`;
  `COINBASE_PRODUCT: Record<Asset, string>`;
  `toRaw(amount: string, decimals: number): bigint`;
  `fromRaw(raw: bigint, decimals: number): string`;
  `tokenByAddress(address: string): Token | undefined`; `VERSION: string`.

- [ ] **Step 1: Create the package files**

`package.json`:

```json
{
  "name": "fusion-signer",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "engines": { "node": ">=22" },
  "scripts": {
    "build": "tsc -p tsconfig.build.json",
    "typecheck": "tsc -p tsconfig.json",
    "test": "vitest run",
    "start": "node dist/main.js"
  }
}
```

`tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "esModuleInterop": true,
    "resolveJsonModule": true,
    "skipLibCheck": true,
    "noEmit": true,
    "types": ["node"]
  },
  "include": ["src", "test"]
}
```

`tsconfig.build.json`:

```json
{
  "extends": "./tsconfig.json",
  "compilerOptions": { "noEmit": false, "rootDir": "src", "outDir": "dist" },
  "include": ["src"]
}
```

`.gitignore` and `.dockerignore` (same content):

```text
node_modules
dist
```

- [ ] **Step 2: Install pinned dependencies**

Run in `docker/images/fusion-signer`:

```bash
nix shell nixpkgs#nodejs_22 nixpkgs#pnpm -c \
  pnpm add --save-exact @1inch/fusion-sdk ethers@6
nix shell nixpkgs#nodejs_22 nixpkgs#pnpm -c \
  pnpm add -D --save-exact typescript vitest @types/node@22
```

Expected: `package.json` gains exact versions and `pnpm-lock.yaml` exists.

- [ ] **Step 3: Write the failing test**

`test/tokens.test.ts`:

```ts
import { describe, expect, it } from "vitest";
import { redact } from "../src/errors.js";
import { TOKENS, fromRaw, toRaw, tokenByAddress } from "../src/tokens.js";

describe("tokens", () => {
  it("parses amounts at each token's decimals", () => {
    expect(toRaw("25.00", TOKENS.USDC.decimals)).toBe(25_000_000n);
    expect(toRaw("0.000291", TOKENS.BTC.decimals)).toBe(29_100n);
    expect(toRaw("1", TOKENS.ETH.decimals)).toBe(10n ** 18n);
  });

  it("formats raw amounts back to decimals", () => {
    expect(fromRaw(29_100n, 8)).toBe("0.000291");
    expect(fromRaw(1n, 18)).toBe("0.000000000000000001");
  });

  it("rejects more decimals than the token has", () => {
    expect(() => toRaw("0.0000001", 6)).toThrow();
  });

  it("finds tokens by address in any case", () => {
    const lower = TOKENS.BTC.address.toLowerCase();
    expect(tokenByAddress(lower)?.key).toBe("BTC");
    const unknown = "0x0000000000000000000000000000000000000001";
    expect(tokenByAddress(unknown)).toBeUndefined();
  });
});

describe("redact", () => {
  it("replaces every secret of 8+ chars", () => {
    const url = "https://base.example/v2/abcdef123456";
    const text = `connect ${url} failed; again ${url}`;
    expect(redact(text, [url, "short"])).toBe(
      "connect [redacted] failed; again [redacted]",
    );
  });
});
```

- [ ] **Step 4: Run the test to verify it fails**

Run: `nix shell nixpkgs#nodejs_22 nixpkgs#pnpm -c pnpm test`
Expected: FAIL, cannot resolve `../src/errors.js` and `../src/tokens.js`.

- [ ] **Step 5: Implement**

`src/errors.ts`:

```ts
export class HttpError extends Error {
  constructor(
    readonly status: number,
    readonly reason: string,
    message?: string,
  ) {
    super(message ?? reason);
  }
}

/** Replace each secret (8+ chars) in `text` with "[redacted]". */
export function redact(text: string, secrets: string[]): string {
  let out = text;
  for (const s of secrets) {
    if (s.length >= 8) out = out.split(s).join("[redacted]");
  }
  return out;
}
```

`src/tokens.ts`:

```ts
import { formatUnits, parseUnits } from "ethers";

export type Asset = "BTC" | "ETH";
export type TokenKey = "USDC" | Asset;
export type Holding = TokenKey | "GAS";

export interface Token {
  key: TokenKey;
  symbol: string;
  address: string;
  decimals: number;
}

export const CHAIN_ID = 8453;
export const LOP_V4 = "0x111111125421cA6dc452d289314280a0f8842A65";

export const TOKENS: Record<TokenKey, Token> = {
  USDC: {
    key: "USDC",
    symbol: "USDC",
    address: "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
    decimals: 6,
  },
  BTC: {
    key: "BTC",
    symbol: "cbBTC",
    address: "0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf",
    decimals: 8,
  },
  ETH: {
    key: "ETH",
    symbol: "WETH",
    address: "0x4200000000000000000000000000000000000006",
    decimals: 18,
  },
};

export const COINBASE_PRODUCT: Record<Asset, string> = {
  BTC: "BTC-USD",
  ETH: "ETH-USD",
};

export const toRaw = (amount: string, decimals: number): bigint =>
  parseUnits(amount, decimals);

export const fromRaw = (raw: bigint, decimals: number): string =>
  formatUnits(raw, decimals);

export const tokenByAddress = (address: string): Token | undefined =>
  Object.values(TOKENS).find(
    (t) => t.address.toLowerCase() === address.toLowerCase(),
  );
```

`src/version.ts`:

```ts
import { readFileSync } from "node:fs";

const pkg = JSON.parse(
  readFileSync(new URL("../package.json", import.meta.url), "utf8"),
) as { version: string };

export const VERSION = pkg.version;
```

- [ ] **Step 6: Run tests and typecheck**

Run: `nix shell nixpkgs#nodejs_22 nixpkgs#pnpm -c pnpm test`
Expected: PASS (5 tests).
Run: `nix shell nixpkgs#nodejs_22 nixpkgs#pnpm -c pnpm typecheck`
Expected: no errors.

- [ ] **Step 7: Commit**

```bash
git add docker/images/fusion-signer
git commit -m "feat(fusion-signer): scaffold package with tokens and errors"
```

---

### Task 2: Configuration and secrets

**Files:**

- Create: `docker/images/fusion-signer/src/config.ts`
- Test: `docker/images/fusion-signer/test/config.test.ts`

**Interfaces:**

- Produces: `interface Limits { maxOrderUsd; maxDailyUsd;
defaultMaxSlippageBps; minOrderIntervalSec }` (numbers);
  `interface Secrets { privateKey; token; oneinchApiKey; rpcUrl }`;
  `interface Config { dryRun; limits; withdrawAddress; ethGasReserve;
dataDir; port; secrets }`; `type Env`; `type ReadSecret`;
  `fileSecret: ReadSecret`; `loadConfig(env, read): Config`;
  `assertNotSelf(config, ownAddress): void`.

- [ ] **Step 1: Write the failing test**

`test/config.test.ts`:

```ts
import { describe, expect, it } from "vitest";
import { assertNotSelf, loadConfig } from "../src/config.js";

// EIP-55 test vector.
const ADDR = "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed";

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
  loadConfig({ WITHDRAW_ADDRESS: ADDR, ...env }, reader(values));

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
  });

  it("refuses a withdraw address equal to the signer", () => {
    const c = load({});
    expect(() => assertNotSelf(c, ADDR.toLowerCase())).toThrow(/own/);
    const other = "0x0000000000000000000000000000000000000002";
    expect(() => assertNotSelf(c, other)).not.toThrow();
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `nix shell nixpkgs#nodejs_22 nixpkgs#pnpm -c pnpm test config`
Expected: FAIL, cannot resolve `../src/config.js`.

- [ ] **Step 3: Implement**

`src/config.ts`:

```ts
import { readFileSync } from "node:fs";
import { getAddress } from "ethers";

export interface Limits {
  maxOrderUsd: number;
  maxDailyUsd: number;
  defaultMaxSlippageBps: number;
  minOrderIntervalSec: number;
}

export interface Secrets {
  privateKey: string;
  token: string;
  oneinchApiKey: string;
  rpcUrl: string;
}

export interface Config {
  dryRun: boolean;
  limits: Limits;
  withdrawAddress: string;
  ethGasReserve: string;
  dataDir: string;
  port: number;
  secrets: Secrets;
}

export type Env = Record<string, string | undefined>;
export type ReadSecret = (name: string) => string;

export const fileSecret: ReadSecret = (name) =>
  readFileSync(`/run/secrets/${name}`, "utf8");

const positive = (name: string, raw: string): number => {
  const value = Number(raw);
  if (!Number.isFinite(value) || value <= 0) {
    throw new Error(`${name} must be a positive number`);
  }
  return value;
};

const num = (env: Env, name: string, fallback: number): number =>
  env[name] === undefined ? fallback : positive(name, env[name]);

const secret = (read: ReadSecret, name: string): string => {
  let value: string;
  try {
    value = read(name).trim();
  } catch {
    throw new Error(`secret ${name} is missing`);
  }
  if (!value) throw new Error(`secret ${name} is empty`);
  return value;
};

const withdrawAddress = (raw: string | undefined): string => {
  let checksummed: string;
  try {
    checksummed = getAddress(raw ?? "");
  } catch {
    throw new Error("WITHDRAW_ADDRESS is not a valid address");
  }
  if (checksummed !== raw) {
    throw new Error("WITHDRAW_ADDRESS must be EIP-55 checksummed");
  }
  return checksummed;
};

export function loadConfig(env: Env, read: ReadSecret): Config {
  const address = withdrawAddress(env.WITHDRAW_ADDRESS);
  const reserve = env.ETH_GAS_RESERVE ?? "0.0003";
  positive("ETH_GAS_RESERVE", reserve);
  const token = secret(read, "fusion_signer_token");
  if (token.length < 32) {
    throw new Error("secret fusion_signer_token is shorter than 32 chars");
  }
  return {
    dryRun: env.DRY_RUN !== "false",
    limits: {
      maxOrderUsd: num(env, "MAX_ORDER_USD", 60),
      maxDailyUsd: num(env, "MAX_DAILY_USD", 150),
      defaultMaxSlippageBps: num(env, "DEFAULT_MAX_SLIPPAGE_BPS", 100),
      minOrderIntervalSec: num(env, "MIN_ORDER_INTERVAL_SEC", 60),
    },
    withdrawAddress: address,
    ethGasReserve: reserve,
    dataDir: env.DATA_DIR ?? "/data",
    port: num(env, "PORT", 8080),
    secrets: {
      privateKey: secret(read, "fusion_signer_key"),
      token,
      oneinchApiKey: secret(read, "oneinch_api_key"),
      rpcUrl: secret(read, "base_rpc_url"),
    },
  };
}

export function assertNotSelf(config: Config, ownAddress: string): void {
  if (getAddress(ownAddress) === config.withdrawAddress) {
    throw new Error("WITHDRAW_ADDRESS must not be the signer's own address");
  }
}
```

Note: `loadConfig({}, ...)` in the test throws "WITHDRAW_ADDRESS is not a
valid address", which matches `/WITHDRAW_ADDRESS/`.

- [ ] **Step 4: Run tests and typecheck**

Run: `nix shell nixpkgs#nodejs_22 nixpkgs#pnpm -c pnpm test`
Expected: PASS.
Run: `nix shell nixpkgs#nodejs_22 nixpkgs#pnpm -c pnpm typecheck`
Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add docker/images/fusion-signer
git commit -m "feat(fusion-signer): load and validate config and secrets"
```

---

### Task 3: Persistent state

**Files:**

- Create: `docker/images/fusion-signer/src/state.ts`
- Test: `docker/images/fusion-signer/test/state.test.ts`

**Interfaces:**

- Produces: `interface StoredResult { bodyHash: string; status: number;
body: unknown }`; `class Store(dir: string, now?: () => number)` with
  `isHalted(): boolean`, `halt(reason: string): void`,
  `getRequest(id): StoredResult | undefined`,
  `putRequest(id, result: StoredResult): void`, `dailyUsd(): number`,
  `addDailyUsd(usd: number): void`, `lastOrderAt(key: string): number |
undefined`, `setLastOrderAt(key: string, ms: number): void`.

- [ ] **Step 1: Write the failing test**

`test/state.test.ts`:

```ts
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
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `nix shell nixpkgs#nodejs_22 nixpkgs#pnpm -c pnpm test state`
Expected: FAIL, cannot resolve `../src/state.js`.

- [ ] **Step 3: Implement**

`src/state.ts`:

```ts
import {
  existsSync,
  mkdirSync,
  readFileSync,
  renameSync,
  writeFileSync,
} from "node:fs";
import { join } from "node:path";

export interface StoredResult {
  bodyHash: string;
  status: number;
  body: unknown;
}

interface State {
  requests: Record<string, StoredResult>;
  dailyUsd: Record<string, number>;
  lastOrderAt: Record<string, number>;
}

export class Store {
  private readonly file: string;
  private readonly haltFile: string;
  private state: State;

  constructor(
    dir: string,
    private readonly now: () => number = Date.now,
  ) {
    mkdirSync(dir, { recursive: true });
    this.file = join(dir, "state.json");
    this.haltFile = join(dir, "halt");
    this.state = existsSync(this.file)
      ? (JSON.parse(readFileSync(this.file, "utf8")) as State)
      : { requests: {}, dailyUsd: {}, lastOrderAt: {} };
  }

  private save(): void {
    const tmp = `${this.file}.tmp`;
    writeFileSync(tmp, JSON.stringify(this.state));
    renameSync(tmp, this.file);
  }

  private today(): string {
    return new Date(this.now()).toISOString().slice(0, 10);
  }

  isHalted(): boolean {
    return existsSync(this.haltFile);
  }

  halt(reason: string): void {
    const at = new Date(this.now()).toISOString();
    writeFileSync(this.haltFile, JSON.stringify({ at, reason }) + "\n");
  }

  getRequest(id: string): StoredResult | undefined {
    return this.state.requests[id];
  }

  putRequest(id: string, result: StoredResult): void {
    this.state.requests[id] = result;
    this.save();
  }

  dailyUsd(): number {
    return this.state.dailyUsd[this.today()] ?? 0;
  }

  addDailyUsd(usd: number): void {
    const day = this.today();
    this.state.dailyUsd[day] = (this.state.dailyUsd[day] ?? 0) + usd;
    this.save();
  }

  lastOrderAt(key: string): number | undefined {
    return this.state.lastOrderAt[key];
  }

  setLastOrderAt(key: string, ms: number): void {
    this.state.lastOrderAt[key] = ms;
    this.save();
  }
}
```

- [ ] **Step 4: Run tests and typecheck**

Run: `nix shell nixpkgs#nodejs_22 nixpkgs#pnpm -c pnpm test`
Expected: PASS.
Run: `nix shell nixpkgs#nodejs_22 nixpkgs#pnpm -c pnpm typecheck`
Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add docker/images/fusion-signer
git commit -m "feat(fusion-signer): add persistent request and limit state"
```

---

### Task 4: Strict request validation

**Files:**

- Create: `docker/images/fusion-signer/src/validate.ts`
- Test: `docker/images/fusion-signer/test/validate.test.ts`

**Interfaces:**

- Consumes: `HttpError` (Task 1); `Asset`, `Holding`, `TokenKey` (Task 1).
- Produces: `type Side = "buy" | "sell"`; `type TradeAmount = { usdc } |
{ units } | { fraction }`; `type WithdrawAmount = { units } |
{ all: true }`; `QuoteRequest { side; asset; amount }`;
  `OrderRequest extends QuoteRequest { requestId; maxSlippageBps? }`;
  `WithdrawRequest { requestId; asset: Holding; amount }`;
  `ApproveRequest { asset: TokenKey }`; `HaltRequest { reason }`;
  `parseQuote`, `parseOrder`, `parseWithdraw`, `parseApprove`,
  `parseHalt`, each `(body: unknown) => <Request>`, throwing
  `HttpError(400, "invalid_body")`.

- [ ] **Step 1: Write the failing test**

`test/validate.test.ts`:

```ts
import { describe, expect, it } from "vitest";
import { HttpError } from "../src/errors.js";
import {
  parseApprove,
  parseHalt,
  parseOrder,
  parseQuote,
  parseWithdraw,
} from "../src/validate.js";

const invalid = (fn: () => unknown) => {
  try {
    fn();
  } catch (e) {
    expect(e).toBeInstanceOf(HttpError);
    expect((e as HttpError).status).toBe(400);
    expect((e as HttpError).reason).toBe("invalid_body");
    return;
  }
  throw new Error("expected a 400");
};

const buy = { side: "buy", asset: "BTC", amount: { usdc: "25.00" } };

describe("parseOrder", () => {
  it("accepts buy, sell units and sell fraction", () => {
    expect(parseOrder({ requestId: "t-1", ...buy })).toEqual({
      requestId: "t-1",
      ...buy,
    });
    const sell = { side: "sell", asset: "ETH", amount: { units: "0.01" } };
    expect(parseOrder({ requestId: "t-2", ...sell }).amount).toEqual({
      units: "0.01",
    });
    const all = { ...sell, amount: { fraction: 1 }, maxSlippageBps: 50 };
    expect(parseOrder({ requestId: "t-3", ...all })).toMatchObject({
      amount: { fraction: 1 },
      maxSlippageBps: 50,
    });
  });

  it("rejects unknown fields and wrong shapes", () => {
    invalid(() => parseOrder({ requestId: "a", ...buy, to: "0x1" }));
    invalid(() => parseOrder({ requestId: "a", ...buy, asset: "SOL" }));
    invalid(() =>
      parseOrder({ requestId: "a", ...buy, amount: { units: "1" } }),
    );
    invalid(() =>
      parseOrder({
        requestId: "a",
        side: "sell",
        asset: "BTC",
        amount: { fraction: 0 },
      }),
    );
    invalid(() =>
      parseOrder({
        requestId: "a",
        side: "sell",
        asset: "BTC",
        amount: { fraction: 1.5 },
      }),
    );
  });

  it("rejects bad decimals, ids and slippage", () => {
    for (const usdc of ["1e3", "-1", "0", "1.", "abc", " 1"]) {
      invalid(() => parseOrder({ requestId: "a", ...buy, amount: { usdc } }));
    }
    invalid(() => parseOrder({ requestId: "has space", ...buy }));
    invalid(() => parseOrder({ requestId: "x".repeat(65), ...buy }));
    for (const b of [0, 1001, 1.5, "50"]) {
      invalid(() => parseOrder({ requestId: "a", ...buy, maxSlippageBps: b }));
    }
    invalid(() => parseOrder(null));
    invalid(() => parseOrder([buy]));
  });
});

describe("other parsers", () => {
  it("parses quotes without a requestId", () => {
    expect(parseQuote(buy)).toEqual(buy);
    invalid(() => parseQuote({ requestId: "a", ...buy }));
  });

  it("parses withdrawals, never with an address", () => {
    expect(
      parseWithdraw({ requestId: "w", asset: "USDC", amount: { all: true } }),
    ).toEqual({ requestId: "w", asset: "USDC", amount: { all: true } });
    expect(
      parseWithdraw({
        requestId: "w",
        asset: "GAS",
        amount: { units: "0.001" },
      }).asset,
    ).toBe("GAS");
    invalid(() =>
      parseWithdraw({
        requestId: "w",
        asset: "USDC",
        amount: { all: true },
        to: "0x1",
      }),
    );
    invalid(() =>
      parseWithdraw({ requestId: "w", asset: "USDC", amount: { all: false } }),
    );
  });

  it("parses approve and halt", () => {
    expect(parseApprove({ asset: "USDC" })).toEqual({ asset: "USDC" });
    invalid(() => parseApprove({ asset: "GAS" }));
    expect(parseHalt({ reason: "manual" })).toEqual({ reason: "manual" });
    invalid(() => parseHalt({ reason: "" }));
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `nix shell nixpkgs#nodejs_22 nixpkgs#pnpm -c pnpm test validate`
Expected: FAIL, cannot resolve `../src/validate.js`.

- [ ] **Step 3: Implement**

`src/validate.ts`:

```ts
import { HttpError } from "./errors.js";
import type { Asset, Holding, TokenKey } from "./tokens.js";

export type Side = "buy" | "sell";
export type TradeAmount =
  { usdc: string } | { units: string } | { fraction: number };
export type WithdrawAmount = { units: string } | { all: true };

export interface QuoteRequest {
  side: Side;
  asset: Asset;
  amount: TradeAmount;
}

export interface OrderRequest extends QuoteRequest {
  requestId: string;
  maxSlippageBps?: number;
}

export interface WithdrawRequest {
  requestId: string;
  asset: Holding;
  amount: WithdrawAmount;
}

export interface ApproveRequest {
  asset: TokenKey;
}

export interface HaltRequest {
  reason: string;
}

type Obj = Record<string, unknown>;

const bad = (message: string): never => {
  throw new HttpError(400, "invalid_body", message);
};

const object = (v: unknown, what: string): Obj => {
  if (typeof v !== "object" || v === null || Array.isArray(v)) {
    return bad(`${what} must be an object`);
  }
  return v as Obj;
};

const onlyKeys = (o: Obj, allowed: string[], what: string): void => {
  for (const k of Object.keys(o)) {
    if (!allowed.includes(k)) bad(`${what}: unknown field ${k}`);
  }
};

const oneOf = <T extends string>(
  v: unknown,
  values: readonly T[],
  what: string,
): T => {
  if (typeof v !== "string" || !values.includes(v as T)) {
    return bad(`${what} must be one of ${values.join(", ")}`);
  }
  return v as T;
};

const DECIMAL = /^(0|[1-9]\d*)(\.\d+)?$/;

const decimal = (v: unknown, what: string): string => {
  if (typeof v !== "string" || !DECIMAL.test(v) || Number(v) <= 0) {
    return bad(`${what} must be a positive decimal string`);
  }
  return v;
};

const REQUEST_ID = /^[A-Za-z0-9._:-]{1,64}$/;

const requestId = (v: unknown): string => {
  if (typeof v !== "string" || !REQUEST_ID.test(v)) {
    return bad("requestId must be 1-64 chars of [A-Za-z0-9._:-]");
  }
  return v;
};

const tradeAmount = (v: unknown, side: Side): TradeAmount => {
  const o = object(v, "amount");
  if (side === "buy") {
    onlyKeys(o, ["usdc"], "amount");
    return { usdc: decimal(o.usdc, "amount.usdc") };
  }
  if ("units" in o) {
    onlyKeys(o, ["units"], "amount");
    return { units: decimal(o.units, "amount.units") };
  }
  onlyKeys(o, ["fraction"], "amount");
  const f = o.fraction;
  if (typeof f !== "number" || !(f > 0 && f <= 1)) {
    return bad("amount.fraction must be in (0, 1]");
  }
  return { fraction: f };
};

const ASSETS = ["BTC", "ETH"] as const;

export function parseQuote(body: unknown): QuoteRequest {
  const o = object(body, "body");
  onlyKeys(o, ["side", "asset", "amount"], "body");
  const side = oneOf(o.side, ["buy", "sell"] as const, "side");
  const asset = oneOf(o.asset, ASSETS, "asset");
  return { side, asset, amount: tradeAmount(o.amount, side) };
}

export function parseOrder(body: unknown): OrderRequest {
  const o = object(body, "body");
  const keys = ["requestId", "side", "asset", "amount", "maxSlippageBps"];
  onlyKeys(o, keys, "body");
  const id = requestId(o.requestId);
  const q = parseQuote({ side: o.side, asset: o.asset, amount: o.amount });
  const req: OrderRequest = { requestId: id, ...q };
  if (o.maxSlippageBps !== undefined) {
    const b = o.maxSlippageBps;
    if (typeof b !== "number" || !Number.isInteger(b) || b < 1 || b > 1000) {
      return bad("maxSlippageBps must be an integer from 1 to 1000");
    }
    req.maxSlippageBps = b;
  }
  return req;
}

export function parseWithdraw(body: unknown): WithdrawRequest {
  const o = object(body, "body");
  onlyKeys(o, ["requestId", "asset", "amount"], "body");
  const id = requestId(o.requestId);
  const holdings = ["USDC", "BTC", "ETH", "GAS"] as const;
  const asset = oneOf(o.asset, holdings, "asset");
  const a = object(o.amount, "amount");
  if ("all" in a) {
    onlyKeys(a, ["all"], "amount");
    if (a.all !== true) return bad("amount.all must be true");
    return { requestId: id, asset, amount: { all: true } };
  }
  onlyKeys(a, ["units"], "amount");
  const units = decimal(a.units, "amount.units");
  return { requestId: id, asset, amount: { units } };
}

export function parseApprove(body: unknown): ApproveRequest {
  const o = object(body, "body");
  onlyKeys(o, ["asset"], "body");
  const keys = ["USDC", "BTC", "ETH"] as const;
  return { asset: oneOf(o.asset, keys, "asset") };
}

export function parseHalt(body: unknown): HaltRequest {
  const o = object(body, "body");
  onlyKeys(o, ["reason"], "body");
  const r = o.reason;
  if (typeof r !== "string" || r.length < 1 || r.length > 200) {
    return bad("reason must be 1-200 chars");
  }
  return { reason: r };
}
```

- [ ] **Step 4: Run tests and typecheck**

Run: `nix shell nixpkgs#nodejs_22 nixpkgs#pnpm -c pnpm test`
Expected: PASS.
Run: `nix shell nixpkgs#nodejs_22 nixpkgs#pnpm -c pnpm typecheck`
Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add docker/images/fusion-signer
git commit -m "feat(fusion-signer): add strict request validation"
```

---

### Task 5: Coinbase reference price

**Files:**

- Create: `docker/images/fusion-signer/src/reference.ts`
- Test: `docker/images/fusion-signer/test/reference.test.ts`

**Interfaces:**

- Consumes: `HttpError`, `COINBASE_PRODUCT`, `Asset` (Task 1).
- Produces: `type FetchLike`; `type Reference = (asset: Asset) =>
Promise<number>`; `makeReference(fetchFn?, timeoutMs?): Reference`,
  throwing `HttpError(403, "no_reference")` on any failure.

- [ ] **Step 1: Write the failing test**

`test/reference.test.ts`:

```ts
import { describe, expect, it } from "vitest";
import { HttpError } from "../src/errors.js";
import { makeReference, type FetchLike } from "../src/reference.js";

const reply =
  (ok: boolean, body: unknown): FetchLike =>
  async () => ({ ok, json: async () => body });

const noRef = async (p: Promise<number>) => {
  const e = await p.catch((err: unknown) => err);
  expect(e).toBeInstanceOf(HttpError);
  expect((e as HttpError).status).toBe(403);
  expect((e as HttpError).reason).toBe("no_reference");
};

describe("makeReference", () => {
  it("returns the Coinbase ticker price for the asset", async () => {
    const urls: string[] = [];
    const fetchFn: FetchLike = async (url) => {
      urls.push(url);
      return { ok: true, json: async () => ({ price: "85000.5" }) };
    };
    expect(await makeReference(fetchFn)("BTC")).toBe(85000.5);
    expect(urls[0]).toBe(
      "https://api.exchange.coinbase.com/products/BTC-USD/ticker",
    );
  });

  it("refuses on HTTP errors, throws and bad prices", async () => {
    await noRef(makeReference(reply(false, {}))("ETH"));
    const boom: FetchLike = async () => {
      throw new Error("network down");
    };
    await noRef(makeReference(boom)("ETH"));
    await noRef(makeReference(reply(true, { price: "0" }))("ETH"));
    await noRef(makeReference(reply(true, {}))("ETH"));
    await noRef(makeReference(reply(true, null))("ETH"));
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `nix shell nixpkgs#nodejs_22 nixpkgs#pnpm -c pnpm test reference`
Expected: FAIL, cannot resolve `../src/reference.js`.

- [ ] **Step 3: Implement**

`src/reference.ts`:

```ts
import { HttpError } from "./errors.js";
import { COINBASE_PRODUCT, type Asset } from "./tokens.js";

export interface FetchResponse {
  ok: boolean;
  json(): Promise<unknown>;
}

export type FetchLike = (
  url: string,
  init: { headers: Record<string, string>; signal: AbortSignal },
) => Promise<FetchResponse>;

export type Reference = (asset: Asset) => Promise<number>;

const noReference = (): never => {
  throw new HttpError(
    403,
    "no_reference",
    "Coinbase reference price unavailable",
  );
};

export function makeReference(
  fetchFn: FetchLike = fetch as unknown as FetchLike,
  timeoutMs = 5000,
): Reference {
  return async (asset) => {
    const product = COINBASE_PRODUCT[asset];
    const url = `https://api.exchange.coinbase.com/products/${product}/ticker`;
    let body: unknown;
    try {
      const res = await fetchFn(url, {
        headers: { "User-Agent": "fusion-signer" },
        signal: AbortSignal.timeout(timeoutMs),
      });
      if (!res.ok) return noReference();
      body = await res.json();
    } catch {
      return noReference();
    }
    const price = Number((body as { price?: unknown } | null)?.price);
    if (!Number.isFinite(price) || price <= 0) return noReference();
    return price;
  };
}
```

- [ ] **Step 4: Run tests and typecheck**

Run: `nix shell nixpkgs#nodejs_22 nixpkgs#pnpm -c pnpm test`
Expected: PASS.
Run: `nix shell nixpkgs#nodejs_22 nixpkgs#pnpm -c pnpm typecheck`
Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add docker/images/fusion-signer
git commit -m "feat(fusion-signer): fetch the Coinbase reference price"
```

---

### Task 6: Ports and the pure guard

**Files:**

- Create: `docker/images/fusion-signer/src/ports.ts`
- Create: `docker/images/fusion-signer/src/guard.ts`
- Test: `docker/images/fusion-signer/test/guard.test.ts`

**Interfaces:**

- Consumes: `HttpError`, `TOKENS`, `fromRaw`, `Asset`, `Token` (Task 1);
  `Limits` (Task 2); `Side` (Task 4).
- Produces (ports): `interface Chain { address; chainId(); decimals(token);
balance(token); ethBalance(); allowance(token, spender);
approve(token, spender, amount); transfer(token, to, amount);
sendEth(to, amount); gasCost(kind: "erc20" | "eth") }` (amounts
  `bigint`, tx results are hashes); `interface OrderSummary { hash; maker;
receiver; makerAsset; takerAsset; makingAmount: bigint;
takingAmount: bigint }` where `receiver` is the SDK's `realReceiver`;
  `interface BuiltOrder { summary; submit(): Promise<string> }`;
  `interface QuoteSummary { startAmount: bigint; endAmount: bigint }`;
  `interface FusionFill { txHash; makerAmount: bigint;
takerAmount: bigint }`; `interface FusionStatus { status; makerAsset;
takerAsset; fills }`; `interface Fusion { quote(from, to, amount);
build(from, to, amount); status(hash) }`.
- Produces (guard): `interface PreChecks`; `checkLimits(c: PreChecks):
void`; `unitPrice(usdcRaw, assetRaw, asset: Token): number`;
  `slippageBps(side, price, ref): number`; `interface Expected`;
  `checkOrder(o: OrderSummary, e: Expected): { worstPrice: number;
slippageBps: number }`. Refusals are `HttpError(403, reason)`.

- [ ] **Step 1: Write the ports file**

`src/ports.ts`:

```ts
export interface Chain {
  readonly address: string;
  chainId(): Promise<number>;
  decimals(token: string): Promise<number>;
  balance(token: string): Promise<bigint>;
  ethBalance(): Promise<bigint>;
  allowance(token: string, spender: string): Promise<bigint>;
  approve(token: string, spender: string, amount: bigint): Promise<string>;
  transfer(token: string, to: string, amount: bigint): Promise<string>;
  sendEth(to: string, amount: bigint): Promise<string>;
  /** Wei for one transfer of this kind, with margin. */
  gasCost(kind: "erc20" | "eth"): Promise<bigint>;
}

export interface OrderSummary {
  hash: string;
  maker: string;
  /** Where the funds actually go (the SDK's realReceiver). */
  receiver: string;
  makerAsset: string;
  takerAsset: string;
  makingAmount: bigint;
  /** Minimum received at the end of the auction. */
  takingAmount: bigint;
}

export interface BuiltOrder {
  summary: OrderSummary;
  /** Signs and submits; resolves to the order hash. */
  submit(): Promise<string>;
}

export interface QuoteSummary {
  startAmount: bigint;
  endAmount: bigint;
}

export interface FusionFill {
  txHash: string;
  makerAmount: bigint;
  takerAmount: bigint;
}

export interface FusionStatus {
  status: string;
  makerAsset: string;
  takerAsset: string;
  fills: FusionFill[];
}

export interface Fusion {
  quote(from: string, to: string, amount: bigint): Promise<QuoteSummary>;
  build(from: string, to: string, amount: bigint): Promise<BuiltOrder>;
  status(hash: string): Promise<FusionStatus>;
}
```

- [ ] **Step 2: Write the failing test**

`test/guard.test.ts`:

```ts
import { describe, expect, it } from "vitest";
import {
  checkLimits,
  checkOrder,
  type Expected,
  type PreChecks,
} from "../src/guard.js";
import { HttpError } from "../src/errors.js";
import type { OrderSummary } from "../src/ports.js";
import { TOKENS } from "../src/tokens.js";

const reason = (fn: () => unknown): string => {
  try {
    fn();
  } catch (e) {
    expect(e).toBeInstanceOf(HttpError);
    expect((e as HttpError).status).toBe(403);
    return (e as HttpError).reason;
  }
  return "passed";
};

const base: PreChecks = {
  limits: {
    maxOrderUsd: 60,
    maxDailyUsd: 150,
    defaultMaxSlippageBps: 100,
    minOrderIntervalSec: 60,
  },
  notionalUsd: 25,
  dailyUsd: 0,
  lastOrderAt: undefined,
  nowMs: 1_000_000,
  sellAmount: 25_000_000n,
  balance: 50_000_000n,
  allowance: 150_000_000n,
};

describe("checkLimits", () => {
  it("passes at the boundaries", () => {
    expect(reason(() => checkLimits({ ...base, notionalUsd: 60 }))).toBe(
      "passed",
    );
    const at = { ...base, lastOrderAt: base.nowMs - 60_000 };
    expect(reason(() => checkLimits(at))).toBe("passed");
  });

  it("refuses in spec order", () => {
    const r = (c: Partial<PreChecks>) =>
      reason(() => checkLimits({ ...base, ...c }));
    expect(r({ notionalUsd: 60.01, sellAmount: 0n })).toBe("order_cap");
    expect(r({ dailyUsd: 130, sellAmount: 0n })).toBe("daily_cap");
    expect(r({ lastOrderAt: base.nowMs - 59_999 })).toBe("too_soon");
    expect(r({ sellAmount: 0n })).toBe("insufficient_balance");
    expect(r({ balance: 1n })).toBe("insufficient_balance");
    expect(r({ allowance: 1n })).toBe("insufficient_allowance");
  });
});

const MAKER = "0x00000000000000000000000000000000000000A1";

// Buy $50 of cbBTC; worst case 0.0004975 BTC => $100,502.51 per BTC.
const buyOrder: OrderSummary = {
  hash: "0x" + "ab".repeat(32),
  maker: MAKER,
  receiver: MAKER.toLowerCase(),
  makerAsset: TOKENS.USDC.address,
  takerAsset: TOKENS.BTC.address.toLowerCase(),
  makingAmount: 50_000_000n,
  takingAmount: 49_750n,
};

const expected: Expected = {
  side: "buy",
  asset: "BTC",
  maker: MAKER,
  sellToken: TOKENS.USDC,
  buyToken: TOKENS.BTC,
  sellAmount: 50_000_000n,
  refPrice: 100_000,
  maxSlippageBps: 100,
};

describe("checkOrder", () => {
  it("returns the worst price and slippage of a good buy", () => {
    const r = checkOrder(buyOrder, expected);
    expect(r.worstPrice).toBeCloseTo(100_502.51, 1);
    expect(r.slippageBps).toBeCloseTo(50.25, 1);
  });

  it("refuses slippage beyond the limit", () => {
    const tight = { ...expected, maxSlippageBps: 50 };
    expect(reason(() => checkOrder(buyOrder, tight))).toBe("slippage");
    const zero = { ...buyOrder, takingAmount: 0n };
    expect(reason(() => checkOrder(zero, expected))).toBe("slippage");
  });

  it("checks a sell against the bid side", () => {
    // Sell 0.0005 BTC for at least $49.60 => $99,200 per BTC, 80 bps.
    const sell: OrderSummary = {
      ...buyOrder,
      makerAsset: TOKENS.BTC.address,
      takerAsset: TOKENS.USDC.address,
      makingAmount: 50_000n,
      takingAmount: 49_600_000n,
    };
    const e: Expected = {
      ...expected,
      side: "sell",
      sellToken: TOKENS.BTC,
      buyToken: TOKENS.USDC,
      sellAmount: 50_000n,
    };
    expect(checkOrder(sell, e).slippageBps).toBeCloseTo(80, 1);
    const tight = { ...e, maxSlippageBps: 79 };
    expect(reason(() => checkOrder(sell, tight))).toBe("slippage");
  });

  it("refuses any mismatch with the request", () => {
    const other = "0x00000000000000000000000000000000000000B2";
    const cases: Partial<OrderSummary>[] = [
      { receiver: other },
      { maker: other },
      { makerAsset: TOKENS.ETH.address },
      { takerAsset: TOKENS.ETH.address },
      { makingAmount: 50_000_001n },
    ];
    for (const c of cases) {
      const r = reason(() => checkOrder({ ...buyOrder, ...c }, expected));
      expect(r).toBe("order_mismatch");
    }
  });
});
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `nix shell nixpkgs#nodejs_22 nixpkgs#pnpm -c pnpm test guard`
Expected: FAIL, cannot resolve `../src/guard.js`.

- [ ] **Step 4: Implement**

`src/guard.ts`:

```ts
import type { Limits } from "./config.js";
import { HttpError } from "./errors.js";
import type { OrderSummary } from "./ports.js";
import { TOKENS, fromRaw, type Asset, type Token } from "./tokens.js";
import type { Side } from "./validate.js";

const refuse = (reason: string, message: string): never => {
  throw new HttpError(403, reason, message);
};

export interface PreChecks {
  limits: Limits;
  notionalUsd: number;
  dailyUsd: number;
  lastOrderAt: number | undefined;
  nowMs: number;
  sellAmount: bigint;
  balance: bigint;
  allowance: bigint;
}

/** Guard checks 4 to 8 of the spec, in order. */
export function checkLimits(c: PreChecks): void {
  const usd = (n: number) => `$${n.toFixed(2)}`;
  if (c.notionalUsd > c.limits.maxOrderUsd) {
    refuse(
      "order_cap",
      `order ${usd(c.notionalUsd)} exceeds ${usd(c.limits.maxOrderUsd)}`,
    );
  }
  if (c.dailyUsd + c.notionalUsd > c.limits.maxDailyUsd) {
    refuse(
      "daily_cap",
      `today ${usd(c.dailyUsd)} + ${usd(c.notionalUsd)} exceeds ` +
        usd(c.limits.maxDailyUsd),
    );
  }
  const gapMs = c.limits.minOrderIntervalSec * 1000;
  if (c.lastOrderAt !== undefined && c.nowMs - c.lastOrderAt < gapMs) {
    refuse("too_soon", "previous order for this asset was too recent");
  }
  if (c.sellAmount <= 0n || c.sellAmount > c.balance) {
    refuse("insufficient_balance", "balance does not cover the order");
  }
  if (c.sellAmount > c.allowance) {
    refuse("insufficient_allowance", "approve the token first");
  }
}

/** USD per whole asset unit implied by a USDC and an asset amount. */
export function unitPrice(
  usdcRaw: bigint,
  assetRaw: bigint,
  asset: Token,
): number {
  const usdc = Number(fromRaw(usdcRaw, TOKENS.USDC.decimals));
  return usdc / Number(fromRaw(assetRaw, asset.decimals));
}

/** Positive bps = worse than the reference for this side. */
export function slippageBps(side: Side, price: number, ref: number): number {
  return side === "buy" ? (price / ref - 1) * 1e4 : (1 - price / ref) * 1e4;
}

export interface Expected {
  side: Side;
  asset: Asset;
  maker: string;
  sellToken: Token;
  buyToken: Token;
  sellAmount: bigint;
  refPrice: number;
  maxSlippageBps: number;
}

/** Guard checks 9 and 10, on the order that would be signed. */
export function checkOrder(
  o: OrderSummary,
  e: Expected,
): { worstPrice: number; slippageBps: number } {
  const same = (a: string, b: string) => a.toLowerCase() === b.toLowerCase();
  const matches =
    same(o.maker, e.maker) &&
    same(o.receiver, e.maker) &&
    same(o.makerAsset, e.sellToken.address) &&
    same(o.takerAsset, e.buyToken.address) &&
    o.makingAmount === e.sellAmount;
  if (!matches) {
    refuse("order_mismatch", "built order does not match the request");
  }
  const asset = TOKENS[e.asset];
  const worstPrice =
    e.side === "buy"
      ? unitPrice(o.makingAmount, o.takingAmount, asset)
      : unitPrice(o.takingAmount, o.makingAmount, asset);
  const bps = slippageBps(e.side, worstPrice, e.refPrice);
  if (!(bps <= e.maxSlippageBps)) {
    refuse("slippage", `worst case is ${bps.toFixed(1)} bps from Coinbase`);
  }
  return { worstPrice, slippageBps: bps };
}
```

Note: the spec checks slippage on the quote's auction-end amount; the
guard checks the built order's `takingAmount`, which is the same minimum and
is what actually gets signed. `!(bps <= max)` also refuses `NaN`.

- [ ] **Step 5: Run tests and typecheck**

Run: `nix shell nixpkgs#nodejs_22 nixpkgs#pnpm -c pnpm test`
Expected: PASS.
Run: `nix shell nixpkgs#nodejs_22 nixpkgs#pnpm -c pnpm typecheck`
Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add docker/images/fusion-signer
git commit -m "feat(fusion-signer): add ports and the order guard"
```

---

### Task 7: Service orders, idempotency and dry run

**Files:**

- Create: `docker/images/fusion-signer/src/service.ts`
- Create: `docker/images/fusion-signer/test/fakes.ts`
- Test: `docker/images/fusion-signer/test/service-orders.test.ts`

**Interfaces:**

- Consumes: everything from Tasks 1 to 6.
- Produces: `interface Result { status: number; body: Record<string,
unknown> }`; `interface Deps { config; store; chain; fusion; reference;
now }`; `bodyHash(value: unknown): string`; `class Service(deps)` with
  `placeOrder(req: OrderRequest): Promise<Result>` (this task) and, in
  Task 8, `status()`, `quote(req)`, `orderStatus(hash)`, `approve(req)`,
  `withdraw(req)`, `halt(req)`.
- Produces (test helpers): `FakeChain`, `FakeFusion`, `testConfig()`,
  `makeService(over?)` in `test/fakes.ts`.

- [ ] **Step 1: Write the fakes**

`test/fakes.ts`:

```ts
import { mkdtempSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type { Config } from "../src/config.js";
import type {
  BuiltOrder,
  Chain,
  Fusion,
  FusionStatus,
  QuoteSummary,
} from "../src/ports.js";
import { Service, type Deps } from "../src/service.js";
import { Store } from "../src/state.js";
import { LOP_V4, TOKENS } from "../src/tokens.js";

export const SIGNER = "0x00000000000000000000000000000000000000A1";
export const METAMASK = "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed";
export const RPC_URL = "https://base.example/v2/rpc-secret-key";

export class FakeChain implements Chain {
  readonly address = SIGNER;
  balances = new Map<string, bigint>();
  allowances = new Map<string, bigint>();
  eth = 10n ** 16n;
  sent: { kind: string; token?: string; to: string; amount: bigint }[] = [];
  failSend = false;

  async chainId() {
    return 8453;
  }
  async decimals(token: string) {
    return Object.values(TOKENS).find((t) => t.address === token)!.decimals;
  }
  async balance(token: string) {
    return this.balances.get(token) ?? 0n;
  }
  async ethBalance() {
    return this.eth;
  }
  async allowance(token: string, spender: string) {
    return spender === LOP_V4 ? (this.allowances.get(token) ?? 0n) : 0n;
  }
  async approve(token: string, spender: string, amount: bigint) {
    this.sent.push({ kind: "approve", token, to: spender, amount });
    return "0xapprove";
  }
  async transfer(token: string, to: string, amount: bigint) {
    if (this.failSend) throw new Error(`rpc ${RPC_URL} timed out`);
    this.sent.push({ kind: "transfer", token, to, amount });
    return "0xtransfer";
  }
  async sendEth(to: string, amount: bigint) {
    if (this.failSend) throw new Error(`rpc ${RPC_URL} timed out`);
    this.sent.push({ kind: "eth", to, amount });
    return "0xeth";
  }
  async gasCost(kind: "erc20" | "eth") {
    return kind === "eth" ? 10n ** 12n : 3n * 10n ** 12n;
  }
}

/** Fills at `price` USD per asset unit, `bps` worse than it. */
export class FakeFusion implements Fusion {
  price = 100_000;
  bps = 20;
  receiver: string | undefined;
  submits = 0;
  failSubmit = false;
  gate: Promise<void> | undefined;
  nextStatus: FusionStatus | undefined;

  private out(from: string, amount: bigint): bigint {
    const worse = 1 - this.bps / 1e4;
    const btc = TOKENS.BTC.decimals;
    if (from === TOKENS.USDC.address) {
      const usd = Number(amount) / 1e6;
      return BigInt(Math.floor((usd / this.price) * worse * 10 ** btc));
    }
    const units = Number(amount) / 10 ** btc;
    return BigInt(Math.floor(units * this.price * worse * 1e6));
  }

  async quote(from: string, _to: string, amount: bigint) {
    const end = this.out(from, amount);
    return { startAmount: end + end / 100n, endAmount: end } as QuoteSummary;
  }

  async build(from: string, to: string, amount: bigint): Promise<BuiltOrder> {
    if (this.gate) await this.gate;
    return {
      summary: {
        hash: "0x" + "cd".repeat(32),
        maker: SIGNER,
        receiver: this.receiver ?? SIGNER,
        makerAsset: from,
        takerAsset: to,
        makingAmount: amount,
        takingAmount: this.out(from, amount),
      },
      submit: async () => {
        if (this.failSubmit) throw new Error(`relay via ${RPC_URL} failed`);
        this.submits += 1;
        return "0x" + "cd".repeat(32);
      },
    };
  }

  async status(): Promise<FusionStatus> {
    return this.nextStatus!;
  }
}

export const testConfig = (over: Partial<Config> = {}): Config => ({
  dryRun: false,
  limits: {
    maxOrderUsd: 60,
    maxDailyUsd: 150,
    defaultMaxSlippageBps: 100,
    minOrderIntervalSec: 60,
  },
  withdrawAddress: METAMASK,
  ethGasReserve: "0.0003",
  dataDir: mkdtempSync(join(tmpdir(), "fusion-signer-")),
  port: 0,
  secrets: {
    privateKey: "0x" + "11".repeat(32),
    token: "t".repeat(64),
    oneinchApiKey: "oneinch-secret-key",
    rpcUrl: RPC_URL,
  },
  ...over,
});

export function makeService(over: Partial<Deps> = {}) {
  const config = over.config ?? testConfig();
  const chain = new FakeChain();
  chain.balances.set(TOKENS.USDC.address, 100_000_000n);
  chain.allowances.set(TOKENS.USDC.address, 150_000_000n);
  const fusion = new FakeFusion();
  let now = Date.UTC(2026, 9, 7, 12);
  const deps: Deps = {
    config,
    store: new Store(config.dataDir, () => now),
    chain,
    fusion,
    reference: async () => 100_000,
    now: () => now,
    ...over,
  };
  const advance = (ms: number) => {
    now += ms;
  };
  return { service: new Service(deps), deps, chain, fusion, advance };
}
```

- [ ] **Step 2: Write the failing test**

`test/service-orders.test.ts`:

```ts
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
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `nix shell nixpkgs#nodejs_22 nixpkgs#pnpm -c pnpm test service`
Expected: FAIL, cannot resolve `../src/service.js`.

- [ ] **Step 4: Implement**

`src/service.ts`:

```ts
import { createHash } from "node:crypto";
import type { Config } from "./config.js";
import { HttpError, redact } from "./errors.js";
import { checkLimits, checkOrder } from "./guard.js";
import type { Chain, Fusion } from "./ports.js";
import type { Reference } from "./reference.js";
import type { Store } from "./state.js";
import {
  LOP_V4,
  TOKENS,
  fromRaw,
  toRaw,
  type Asset,
  type Token,
} from "./tokens.js";
import type { OrderRequest, QuoteRequest, Side } from "./validate.js";

export interface Result {
  status: number;
  body: Record<string, unknown>;
}

export interface Deps {
  config: Config;
  store: Store;
  chain: Chain;
  fusion: Fusion;
  reference: Reference;
  now: () => number;
}

export const bodyHash = (value: unknown): string =>
  createHash("sha256").update(JSON.stringify(value)).digest("hex");

const upstream = (err: unknown, what: string): HttpError =>
  new HttpError(502, "upstream", `${what}: ${(err as Error).message}`);

export class Service {
  private readonly inFlight = new Set<string>();

  constructor(private readonly d: Deps) {}

  private secrets(): string[] {
    return Object.values(this.d.config.secrets);
  }

  /** Runs `run` once per requestId and stores the outcome. */
  protected async once(
    requestId: string,
    hash: string,
    run: () => Promise<Result>,
  ): Promise<Result> {
    const stored = this.d.store.getRequest(requestId);
    if (stored) {
      if (stored.bodyHash !== hash) {
        throw new HttpError(
          409,
          "request_id_conflict",
          "requestId was used with a different request",
        );
      }
      return { status: stored.status, body: stored.body as Result["body"] };
    }
    if (this.inFlight.has(requestId)) {
      throw new HttpError(
        409,
        "request_in_progress",
        "requestId is still being processed",
      );
    }
    this.inFlight.add(requestId);
    try {
      let result: Result;
      try {
        result = await run();
      } catch (err) {
        if (!(err instanceof HttpError) || err.status === 400) throw err;
        const error = redact(err.message, this.secrets());
        result = { status: err.status, body: { error, reason: err.reason } };
      }
      this.d.store.putRequest(requestId, { bodyHash: hash, ...result });
      return result;
    } finally {
      this.inFlight.delete(requestId);
    }
  }

  protected tokensFor(side: Side, asset: Asset) {
    return side === "buy"
      ? { sell: TOKENS.USDC, buy: TOKENS[asset] }
      : { sell: TOKENS[asset], buy: TOKENS.USDC };
  }

  protected parseAmount(amount: string, decimals: number): bigint {
    try {
      return toRaw(amount, decimals);
    } catch {
      throw new HttpError(
        400,
        "invalid_body",
        `amount has more than ${decimals} decimals`,
      );
    }
  }

  protected async sellAmount(req: QuoteRequest, sell: Token) {
    const a = req.amount;
    if ("usdc" in a) return this.parseAmount(a.usdc, TOKENS.USDC.decimals);
    if ("units" in a) return this.parseAmount(a.units, sell.decimals);
    const balance = await this.d.chain.balance(sell.address);
    return (balance * BigInt(Math.round(a.fraction * 1e6))) / 1_000_000n;
  }

  async placeOrder(req: OrderRequest): Promise<Result> {
    const { store, chain, fusion, config } = this.d;
    if (store.isHalted()) {
      throw new HttpError(423, "halted", "signer is halted");
    }
    return this.once(req.requestId, bodyHash(req), async () => {
      const { sell, buy } = this.tokensFor(req.side, req.asset);
      const refPrice = await this.d.reference(req.asset);
      const sellAmount = await this.sellAmount(req, sell);
      const sellUnits = Number(fromRaw(sellAmount, sell.decimals));
      const notionalUsd = sellUnits * (req.side === "buy" ? 1 : refPrice);
      checkLimits({
        limits: config.limits,
        notionalUsd,
        dailyUsd: store.dailyUsd(),
        lastOrderAt: store.lastOrderAt(req.asset),
        nowMs: this.d.now(),
        sellAmount,
        balance: await chain.balance(sell.address),
        allowance: await chain.allowance(sell.address, LOP_V4),
      });
      const built = await fusion.build(sell.address, buy.address, sellAmount);
      const check = checkOrder(built.summary, {
        side: req.side,
        asset: req.asset,
        maker: chain.address,
        sellToken: sell,
        buyToken: buy,
        sellAmount,
        refPrice,
        maxSlippageBps:
          req.maxSlippageBps ?? config.limits.defaultMaxSlippageBps,
      });
      const detail = {
        requestId: req.requestId,
        side: req.side,
        asset: req.asset,
        sellToken: sell.symbol,
        sellAmount: fromRaw(sellAmount, sell.decimals),
        buyToken: buy.symbol,
        minBuyAmount: fromRaw(built.summary.takingAmount, buy.decimals),
        notionalUsd,
        refPrice,
        worstPrice: check.worstPrice,
        slippageBps: check.slippageBps,
      };
      if (config.dryRun) {
        return { status: 200, body: { ...detail, status: "dry_run" } };
      }
      store.addDailyUsd(notionalUsd);
      store.setLastOrderAt(req.asset, this.d.now());
      let orderHash: string;
      try {
        orderHash = await built.submit();
      } catch (err) {
        throw upstream(err, "submit failed");
      }
      return {
        status: 200,
        body: { ...detail, orderHash, status: "pending" },
      };
    });
  }
}
```

- [ ] **Step 5: Run tests and typecheck**

Run: `nix shell nixpkgs#nodejs_22 nixpkgs#pnpm -c pnpm test`
Expected: PASS.
Run: `nix shell nixpkgs#nodejs_22 nixpkgs#pnpm -c pnpm typecheck`
Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add docker/images/fusion-signer
git commit -m "feat(fusion-signer): place guarded orders with idempotency"
```

---

### Task 8: Status, quote, order status, approve, withdraw and halt

**Files:**

- Modify: `docker/images/fusion-signer/src/service.ts` (add methods to
  `Service`, extend imports)
- Test: `docker/images/fusion-signer/test/service-other.test.ts`

**Interfaces:**

- Consumes: Task 7's `Service`, `once`, `tokensFor`, `sellAmount`,
  `parseAmount`, `upstream`; `unitPrice`, `slippageBps` (Task 6);
  `tokenByAddress`, `CHAIN_ID` (Task 1); `VERSION` (Task 1).
- Produces: `Service.status(): Promise<Result>`;
  `quote(req: QuoteRequest)`; `orderStatus(hash: string)`;
  `approve(req: ApproveRequest)`; `withdraw(req: WithdrawRequest)`;
  `halt(req: HaltRequest)`, all `Promise<Result>`.

- [ ] **Step 1: Write the failing test**

`test/service-other.test.ts`:

```ts
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
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `nix shell nixpkgs#nodejs_22 nixpkgs#pnpm -c pnpm test service-other`
Expected: FAIL, `service.status is not a function` (and the other methods).

- [ ] **Step 3: Implement**

In `src/service.ts`, replace the imports from `./guard.js`, `./tokens.js`
and `./validate.js` with:

```ts
import { checkLimits, checkOrder, slippageBps, unitPrice } from "./guard.js";
import {
  CHAIN_ID,
  LOP_V4,
  TOKENS,
  fromRaw,
  toRaw,
  tokenByAddress,
  type Asset,
  type Token,
  type TokenKey,
} from "./tokens.js";
import type {
  ApproveRequest,
  HaltRequest,
  OrderRequest,
  QuoteRequest,
  Side,
  WithdrawRequest,
} from "./validate.js";
import { VERSION } from "./version.js";
```

Add these methods inside `class Service`, after `placeOrder`:

```ts
  async status(): Promise<Result> {
    const { chain, config, store } = this.d;
    const balances: Record<string, string> = {};
    const allowances: Record<string, string> = {};
    for (const t of Object.values(TOKENS)) {
      balances[t.key] = fromRaw(await chain.balance(t.address), t.decimals);
      const allowed = await chain.allowance(t.address, LOP_V4);
      allowances[t.key] = fromRaw(allowed, t.decimals);
    }
    balances.GAS = fromRaw(await chain.ethBalance(), 18);
    return {
      status: 200,
      body: {
        address: chain.address,
        chainId: CHAIN_ID,
        balances,
        allowances,
        limits: config.limits,
        dailyUsd: store.dailyUsd(),
        dryRun: config.dryRun,
        halted: store.isHalted(),
        withdrawAddress: config.withdrawAddress,
        version: VERSION,
      },
    };
  }

  async quote(req: QuoteRequest): Promise<Result> {
    const { sell, buy } = this.tokensFor(req.side, req.asset);
    const refPrice = await this.d.reference(req.asset);
    const amount = await this.sellAmount(req, sell);
    if (amount <= 0n) {
      throw new HttpError(403, "insufficient_balance", "nothing to sell");
    }
    const q = await this.d.fusion.quote(sell.address, buy.address, amount);
    const asset = TOKENS[req.asset];
    const price = (out: bigint) =>
      req.side === "buy"
        ? unitPrice(amount, out, asset)
        : unitPrice(out, amount, asset);
    const worstPrice = price(q.endAmount);
    return {
      status: 200,
      body: {
        side: req.side,
        asset: req.asset,
        sellToken: sell.symbol,
        sellAmount: fromRaw(amount, sell.decimals),
        buyToken: buy.symbol,
        startAmount: fromRaw(q.startAmount, buy.decimals),
        endAmount: fromRaw(q.endAmount, buy.decimals),
        refPrice,
        startPrice: price(q.startAmount),
        worstPrice,
        slippageBps: slippageBps(req.side, worstPrice, refPrice),
      },
    };
  }

  async orderStatus(hash: string): Promise<Result> {
    const s = await this.d.fusion.status(hash);
    const maker = tokenByAddress(s.makerAsset);
    const taker = tokenByAddress(s.takerAsset);
    if (!maker || !taker) {
      throw new HttpError(502, "upstream", "order uses unknown tokens");
    }
    const sum = (key: "makerAmount" | "takerAmount") =>
      s.fills.reduce((n, f) => n + f[key], 0n);
    const sold = sum("makerAmount");
    const bought = sum("takerAmount");
    const asset = maker.key === "USDC" ? taker : maker;
    let effectivePrice: number | null = null;
    if (sold > 0n && bought > 0n) {
      effectivePrice =
        maker.key === "USDC"
          ? unitPrice(sold, bought, asset)
          : unitPrice(bought, sold, asset);
    }
    return {
      status: 200,
      body: {
        orderHash: hash,
        status: s.status,
        sellToken: maker.symbol,
        soldAmount: fromRaw(sold, maker.decimals),
        buyToken: taker.symbol,
        boughtAmount: fromRaw(bought, taker.decimals),
        effectivePrice,
        fills: s.fills.map((f) => ({
          txHash: f.txHash,
          soldAmount: fromRaw(f.makerAmount, maker.decimals),
          boughtAmount: fromRaw(f.takerAmount, taker.decimals),
        })),
      },
    };
  }

  async approve(req: ApproveRequest): Promise<Result> {
    const { config, chain } = this.d;
    const token = TOKENS[req.asset];
    const cap = config.limits.maxDailyUsd;
    const units =
      req.asset === "USDC" ? cap : cap / (await this.d.reference(req.asset));
    const amount = toRaw(units.toFixed(token.decimals), token.decimals);
    const detail = {
      asset: req.asset,
      token: token.symbol,
      spender: LOP_V4,
      amount: fromRaw(amount, token.decimals),
    };
    if (config.dryRun) {
      return { status: 200, body: { ...detail, status: "dry_run" } };
    }
    let txHash: string;
    try {
      txHash = await chain.approve(token.address, LOP_V4, amount);
    } catch (err) {
      throw upstream(err, "approve failed");
    }
    return { status: 200, body: { ...detail, status: "sent", txHash } };
  }

  async withdraw(req: WithdrawRequest): Promise<Result> {
    return this.once(req.requestId, bodyHash(req), async () => {
      const { chain, config } = this.d;
      const to = config.withdrawAddress;
      const isGas = req.asset === "GAS";
      const token = isGas ? undefined : TOKENS[req.asset as TokenKey];
      const decimals = token?.decimals ?? 18;
      const balance = token
        ? await chain.balance(token.address)
        : await chain.ethBalance();
      const gas = await chain.gasCost(isGas ? "eth" : "erc20");
      const all = "all" in req.amount;
      const refuse = (reason: string, message: string): never => {
        throw new HttpError(403, reason, message);
      };
      if (isGas && all && balance <= gas) {
        refuse("no_gas", "not enough ETH to pay for the transfer");
      }
      const amount =
        "all" in req.amount
          ? isGas
            ? balance - gas
            : balance
          : this.parseAmount(req.amount.units, decimals);
      if (amount <= 0n || amount > balance) {
        refuse("insufficient_balance", "balance does not cover it");
      }
      if (isGas && !all) {
        const reserve = toRaw(config.ethGasReserve, 18);
        if (balance - amount < reserve) {
          refuse("gas_reserve", "would leave less than ETH_GAS_RESERVE");
        }
      }
      if (!isGas && (await chain.ethBalance()) < gas) {
        refuse("no_gas", "not enough ETH to pay for the transfer");
      }
      const detail = {
        requestId: req.requestId,
        asset: req.asset,
        token: token?.symbol ?? "ETH",
        to,
        amount: fromRaw(amount, decimals),
      };
      if (config.dryRun) {
        return { status: 200, body: { ...detail, status: "dry_run" } };
      }
      let txHash: string;
      try {
        txHash = token
          ? await chain.transfer(token.address, to, amount)
          : await chain.sendEth(to, amount);
      } catch (err) {
        throw upstream(err, "withdraw failed");
      }
      return { status: 200, body: { ...detail, status: "sent", txHash } };
    });
  }

  async halt(req: HaltRequest): Promise<Result> {
    this.d.store.halt(req.reason);
    return { status: 200, body: { halted: true } };
  }
```

- [ ] **Step 4: Run tests and typecheck**

Run: `nix shell nixpkgs#nodejs_22 nixpkgs#pnpm -c pnpm test`
Expected: PASS (all files).
Run: `nix shell nixpkgs#nodejs_22 nixpkgs#pnpm -c pnpm typecheck`
Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add docker/images/fusion-signer
git commit -m "feat(fusion-signer): add status, quote, approve and withdraw"
```

---

### Task 9: HTTP server

**Files:**

- Create: `docker/images/fusion-signer/src/server.ts`
- Test: `docker/images/fusion-signer/test/server.test.ts`

**Interfaces:**

- Consumes: `HttpError`, `redact` (Task 1); parsers (Task 4); `Service`,
  `Result` (Tasks 7-8).
- Produces: `interface ServerOptions { service: Service; token: string;
secrets: string[]; log?: (line: Record<string, unknown>) => void }`;
  `buildServer(opts): http.Server`.

- [ ] **Step 1: Write the failing test**

`test/server.test.ts`:

```ts
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
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `nix shell nixpkgs#nodejs_22 nixpkgs#pnpm -c pnpm test server`
Expected: FAIL, cannot resolve `../src/server.js`.

- [ ] **Step 3: Implement**

`src/server.ts`:

```ts
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
        const body = JSON.parse(text) as Record<string, unknown>;
        log({
          ts: new Date().toISOString(),
          method: req.method,
          path,
          status: result.status,
          reason: body.reason,
          requestId: body.requestId,
          orderHash: body.orderHash,
          ms: Date.now() - started,
        });
      });
  });
}
```

- [ ] **Step 4: Run tests and typecheck**

Run: `nix shell nixpkgs#nodejs_22 nixpkgs#pnpm -c pnpm test`
Expected: PASS.
Run: `nix shell nixpkgs#nodejs_22 nixpkgs#pnpm -c pnpm typecheck`
Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add docker/images/fusion-signer
git commit -m "feat(fusion-signer): serve the API with auth and redaction"
```

---

### Task 10: Real adapters, startup checks, main and quote probe

**Files:**

- Create: `docker/images/fusion-signer/src/startup.ts`
- Create: `docker/images/fusion-signer/src/adapters/ethers-chain.ts`
- Create: `docker/images/fusion-signer/src/adapters/fusion-client.ts`
- Create: `docker/images/fusion-signer/src/main.ts`
- Create: `docker/images/fusion-signer/src/quote-check.ts`
- Test: `docker/images/fusion-signer/test/startup.test.ts`

**Interfaces:**

- Consumes: `Chain`, `Fusion` and the port types (Task 6); `Config`,
  `assertNotSelf`, `loadConfig`, `fileSecret` (Task 2); `Store` (Task 3);
  `makeReference` (Task 5); `Service` (Tasks 7-8); `buildServer` (Task 9);
  `redact` (Task 1).
- Produces: `startupChecks(chain: Chain, config: Config): Promise<void>`;
  `class EthersChain implements Chain` with
  `static connect(rpcUrl, privateKey)` and `readonly provider`;
  `class FusionClient implements Fusion` with
  `constructor(walletAddress, privateKey, provider, authKey)`.

- [ ] **Step 1: Write the failing test**

`test/startup.test.ts`:

```ts
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
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `nix shell nixpkgs#nodejs_22 nixpkgs#pnpm -c pnpm test startup`
Expected: FAIL, cannot resolve `../src/startup.js`.

- [ ] **Step 3: Implement the startup checks**

`src/startup.ts`:

```ts
import { assertNotSelf, type Config } from "./config.js";
import type { Chain } from "./ports.js";
import { CHAIN_ID, TOKENS } from "./tokens.js";

export async function startupChecks(
  chain: Chain,
  config: Config,
): Promise<void> {
  const id = await chain.chainId();
  if (id !== CHAIN_ID) {
    throw new Error(`RPC is chain ${id}, expected Base (${CHAIN_ID})`);
  }
  for (const t of Object.values(TOKENS)) {
    const d = await chain.decimals(t.address);
    if (d !== t.decimals) {
      throw new Error(
        `${t.symbol} has ${d} decimals on-chain, expected ${t.decimals}`,
      );
    }
  }
  assertNotSelf(config, chain.address);
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `nix shell nixpkgs#nodejs_22 nixpkgs#pnpm -c pnpm test startup`
Expected: PASS (4 tests).

- [ ] **Step 5: Implement the ethers adapter**

`src/adapters/ethers-chain.ts`:

```ts
import { Contract, JsonRpcProvider, Wallet } from "ethers";
import type { Chain } from "../ports.js";
import { CHAIN_ID } from "../tokens.js";

const ERC20 = [
  "function decimals() view returns (uint8)",
  "function balanceOf(address) view returns (uint256)",
  "function allowance(address,address) view returns (uint256)",
  "function approve(address,uint256) returns (bool)",
  "function transfer(address,uint256) returns (bool)",
];

/** Base also charges an L1 data fee that gas estimates leave out. */
const L1_FEE_MARGIN = 10n ** 13n; // 0.00001 ETH

export class EthersChain implements Chain {
  readonly address: string;
  private readonly wallet: Wallet;

  constructor(
    readonly provider: JsonRpcProvider,
    privateKey: string,
  ) {
    this.wallet = new Wallet(privateKey, provider);
    this.address = this.wallet.address;
  }

  static connect(rpcUrl: string, privateKey: string): EthersChain {
    const provider = new JsonRpcProvider(rpcUrl, CHAIN_ID, {
      staticNetwork: true,
    });
    return new EthersChain(provider, privateKey);
  }

  private fn(token: string, name: string) {
    return new Contract(token, ERC20, this.wallet).getFunction(name);
  }

  async chainId(): Promise<number> {
    return Number(await this.provider.send("eth_chainId", []));
  }

  async decimals(token: string): Promise<number> {
    return Number(await this.fn(token, "decimals")());
  }

  async balance(token: string): Promise<bigint> {
    return (await this.fn(token, "balanceOf")(this.address)) as bigint;
  }

  ethBalance(): Promise<bigint> {
    return this.provider.getBalance(this.address);
  }

  async allowance(token: string, spender: string): Promise<bigint> {
    const read = this.fn(token, "allowance");
    return (await read(this.address, spender)) as bigint;
  }

  async approve(token: string, spender: string, amount: bigint) {
    const tx = await this.fn(token, "approve")(spender, amount);
    return tx.hash as string;
  }

  async transfer(token: string, to: string, amount: bigint) {
    const tx = await this.fn(token, "transfer")(to, amount);
    return tx.hash as string;
  }

  async sendEth(to: string, amount: bigint): Promise<string> {
    const tx = await this.wallet.sendTransaction({ to, value: amount });
    return tx.hash;
  }

  async gasCost(kind: "erc20" | "eth"): Promise<bigint> {
    const fee = await this.provider.getFeeData();
    const price = fee.maxFeePerGas ?? fee.gasPrice ?? 0n;
    const limit = kind === "eth" ? 21_000n : 65_000n;
    return (limit * price * 12n) / 10n + L1_FEE_MARGIN;
  }
}
```

- [ ] **Step 6: Implement the Fusion adapter**

`src/adapters/fusion-client.ts`:

```ts
import {
  FusionSDK,
  NetworkEnum,
  PrivateKeyProviderConnector,
  type Web3Like,
} from "@1inch/fusion-sdk";
import type { JsonRpcProvider } from "ethers";
import type {
  BuiltOrder,
  Fusion,
  FusionStatus,
  QuoteSummary,
} from "../ports.js";

export class FusionClient implements Fusion {
  private readonly sdk: FusionSDK;

  constructor(
    private readonly walletAddress: string,
    privateKey: string,
    provider: JsonRpcProvider,
    authKey: string,
  ) {
    const web3: Web3Like = {
      eth: { call: (tx) => provider.call(tx) },
      extend() {},
    };
    this.sdk = new FusionSDK({
      url: "https://api.1inch.com/fusion",
      network: NetworkEnum.COINBASE, // Base, chain id 8453
      blockchainProvider: new PrivateKeyProviderConnector(privateKey, web3),
      authKey,
    });
  }

  private params(from: string, to: string, amount: bigint) {
    return {
      fromTokenAddress: from,
      toTokenAddress: to,
      amount: amount.toString(),
      walletAddress: this.walletAddress,
    };
  }

  async quote(from: string, to: string, amount: bigint) {
    const q = await this.sdk.getQuote(this.params(from, to, amount));
    const preset = q.presets[q.recommendedPreset];
    if (!preset) throw new Error("1inch quote has no recommended preset");
    return {
      startAmount: preset.auctionStartAmount,
      endAmount: preset.auctionEndAmount,
    } satisfies QuoteSummary;
  }

  async build(from: string, to: string, amount: bigint): Promise<BuiltOrder> {
    const prepared = await this.sdk.createOrder(this.params(from, to, amount));
    const o = prepared.order;
    return {
      summary: {
        hash: prepared.hash,
        maker: o.maker.toString(),
        receiver: o.realReceiver.toString(),
        makerAsset: o.makerAsset.toString(),
        takerAsset: o.takerAsset.toString(),
        makingAmount: o.makingAmount,
        takingAmount: o.takingAmount,
      },
      submit: async () => {
        const info = await this.sdk.submitOrder(o, prepared.quoteId);
        return info.orderHash;
      },
    };
  }

  async status(hash: string): Promise<FusionStatus> {
    const r = await this.sdk.getOrderStatus(hash);
    return {
      status: r.status,
      makerAsset: r.order.makerAsset,
      takerAsset: r.order.takerAsset,
      fills: r.fills.map((f) => ({
        txHash: f.txHash,
        makerAmount: BigInt(f.filledMakerAmount),
        takerAmount: BigInt(f.filledAuctionTakerAmount),
      })),
    };
  }
}
```

If `pnpm typecheck` reports a type mismatch on `q.presets[...]` or
`provider.call(tx)`, read the installed SDK's `.d.ts`
(`node_modules/@1inch/fusion-sdk/dist/types/**`) and adjust only the
expression's type (for example `q.presets[q.recommendedPreset as
keyof typeof q.presets]`); do not change behavior.

- [ ] **Step 7: Implement main and the quote probe**

`src/main.ts`:

```ts
import { EthersChain } from "./adapters/ethers-chain.js";
import { FusionClient } from "./adapters/fusion-client.js";
import { fileSecret, loadConfig } from "./config.js";
import { redact } from "./errors.js";
import { makeReference } from "./reference.js";
import { buildServer } from "./server.js";
import { Service } from "./service.js";
import { startupChecks } from "./startup.js";
import { Store } from "./state.js";

let secrets: string[] = [];
const log = (line: Record<string, unknown>) =>
  console.log(redact(JSON.stringify(line), secrets));

async function main(): Promise<void> {
  const config = loadConfig(process.env, fileSecret);
  secrets = Object.values(config.secrets);
  const { privateKey, rpcUrl, oneinchApiKey, token } = config.secrets;
  const chain = EthersChain.connect(rpcUrl, privateKey);
  await startupChecks(chain, config);
  const fusion = new FusionClient(
    chain.address,
    privateKey,
    chain.provider,
    oneinchApiKey,
  );
  const service = new Service({
    config,
    store: new Store(config.dataDir),
    chain,
    fusion,
    reference: makeReference(),
    now: Date.now,
  });
  buildServer({ service, token, secrets, log }).listen(config.port, () =>
    log({
      ts: new Date().toISOString(),
      event: "listening",
      port: config.port,
      address: chain.address,
      dryRun: config.dryRun,
    }),
  );
}

main().catch((err: unknown) => {
  log({ event: "fatal", error: (err as Error).message });
  process.exit(1);
});
```

`src/quote-check.ts` (testing layer 2; never signs):

```ts
import { JsonRpcProvider, Wallet } from "ethers";
import { FusionClient } from "./adapters/fusion-client.js";
import { slippageBps, unitPrice } from "./guard.js";
import { makeReference } from "./reference.js";
import { CHAIN_ID, TOKENS, toRaw, type Asset } from "./tokens.js";

// Needs ONEINCH_API_KEY and BASE_RPC_URL in the environment.
const { ONEINCH_API_KEY, BASE_RPC_URL } = process.env;
if (!ONEINCH_API_KEY || !BASE_RPC_URL) {
  throw new Error("set ONEINCH_API_KEY and BASE_RPC_URL");
}
const provider = new JsonRpcProvider(BASE_RPC_URL, CHAIN_ID, {
  staticNetwork: true,
});
const wallet = Wallet.createRandom(); // empty, never funded
const fusion = new FusionClient(
  wallet.address,
  wallet.privateKey,
  provider,
  ONEINCH_API_KEY,
);
const reference = makeReference();

for (const asset of ["BTC", "ETH"] as Asset[]) {
  const ref = await reference(asset);
  for (const usd of ["5", "25", "50"]) {
    const amount = toRaw(usd, 6);
    const token = TOKENS[asset];
    try {
      const q = await fusion.quote(TOKENS.USDC.address, token.address, amount);
      const worst = unitPrice(amount, q.endAmount, token);
      const bps = slippageBps("buy", worst, ref).toFixed(1);
      console.log(
        `${asset} $${usd}: worst ${worst.toFixed(2)} vs ${ref}` +
          ` = ${bps} bps`,
      );
    } catch (err) {
      console.log(`${asset} $${usd}: no quote (${(err as Error).message})`);
    }
  }
}
```

- [ ] **Step 8: Run tests, typecheck and build**

Run: `nix shell nixpkgs#nodejs_22 nixpkgs#pnpm -c pnpm test`
Expected: PASS.
Run: `nix shell nixpkgs#nodejs_22 nixpkgs#pnpm -c pnpm typecheck`
Expected: no errors.
Run: `nix shell nixpkgs#nodejs_22 nixpkgs#pnpm -c pnpm build`
Expected: `dist/main.js` and `dist/quote-check.js` exist.

- [ ] **Step 9: Smoke-test that main refuses to start without secrets**

Run:

```bash
nix shell nixpkgs#nodejs_22 -c env \
  WITHDRAW_ADDRESS=0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed node dist/main.js
```

Expected: one JSON line `{"event":"fatal","error":"secret
fusion_signer_token is missing"}` and exit code 1.

- [ ] **Step 10: Commit**

```bash
git add docker/images/fusion-signer
git commit -m "feat(fusion-signer): add ethers and Fusion adapters and main"
```

---

### Task 11: Docker image and CI workflow

**Files:**

- Create: `docker/images/fusion-signer/Dockerfile`
- Create: `.github/workflows/fusion-signer-image.yml`

**Interfaces:**

- Consumes: the package from Tasks 1-10 (`pnpm test`, `pnpm build`,
  `dist/main.js`).
- Produces: image `ghcr.io/soriphoono/fusion-signer:<package version>`
  that listens on 8080, runs as `node`, stores state in `/data` and has a
  healthcheck on `/health`.

- [ ] **Step 1: Write the Dockerfile**

`docker/images/fusion-signer/Dockerfile`:

```dockerfile
# --- fusion-signer: guarded 1inch Fusion signer for Base
FROM node:22-alpine AS build
WORKDIR /app
RUN corepack enable
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
COPY tsconfig.json tsconfig.build.json ./
COPY src ./src
COPY test ./test
# Tests gate the image: a failing test fails the build.
RUN pnpm test && pnpm run build

FROM node:22-alpine AS deps
WORKDIR /app
RUN corepack enable
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile --prod

FROM node:22-alpine
WORKDIR /app
ENV NODE_ENV=production DATA_DIR=/data PORT=8080
COPY --from=deps /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY package.json ./
RUN mkdir -p /data && chown node:node /data
USER node
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s \
  CMD wget -qO- http://127.0.0.1:8080/health || exit 1
CMD ["node", "dist/main.js"]
```

- [ ] **Step 2: Build the image locally**

Run: `docker build -t fusion-signer:dev docker/images/fusion-signer`
Expected: build succeeds; the test stage prints all tests passing.

- [ ] **Step 3: Check that the container refuses to start without secrets**

Run:

```bash
docker run --rm \
  -e WITHDRAW_ADDRESS=0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed \
  fusion-signer:dev
```

Expected: `{"event":"fatal","error":"secret fusion_signer_token is
missing"}`, exit 1.

- [ ] **Step 4: Write the workflow**

`.github/workflows/fusion-signer-image.yml`:

```yaml
# --- Build and publish the fusion-signer image (tests run in the build)
name: fusion-signer image

on:
  workflow_dispatch:
  push:
    branches:
      - main
      - feat/fusion-signer
    paths:
      - docker/images/fusion-signer/**
      - .github/workflows/fusion-signer-image.yml

permissions:
  contents: read
  packages: write

jobs:
  build:
    runs-on: "ubuntu-latest"
    steps:
      - name: "Checking out repository..."
        uses: actions/checkout@v4
      - name: "Reading the version from package.json..."
        id: version
        run: |
          pkg=docker/images/fusion-signer/package.json
          echo "tag=$(jq -r .version "$pkg")" >> "$GITHUB_OUTPUT"
      - name: "Setting up Buildx..."
        uses: docker/setup-buildx-action@v3
      - name: "Logging in to GHCR..."
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: "Building and pushing..."
        uses: docker/build-push-action@v6
        with:
          context: docker/images/fusion-signer
          push: true
          tags: >-
            ghcr.io/soriphoono/fusion-signer:${{ steps.version.outputs.tag }}
          # OCI source label links the package to this repository.
          labels: >-
            org.opencontainers.image.source=https://github.com/${{
            github.repository }}
```

- [ ] **Step 5: Commit (actionlint runs in pre-commit)**

```bash
git add docker/images/fusion-signer/Dockerfile \
  .github/workflows/fusion-signer-image.yml
git commit -m "ci: build and publish fusion-signer image"
```

---

### Task 12: Secret sealing and wallet generation scripts

**Files:**

- Create: `docker/images/fusion-signer/scripts/seal-secret.sh`
- Create: `docker/images/fusion-signer/scripts/new-wallet.sh`

**Interfaces:**

- Produces: `seal-secret.sh <name>` reads a value from stdin and writes
  `docker/stacks/n8n/secrets/<name>`, SOPS-encrypted for the user and VPS
  recipients, refusing to overwrite. `new-wallet.sh` generates a wallet,
  seals the private key as `fusion-signer-key` and prints only the address.
  Both honour `SOPS` (default `sops`) and `SECRETS_DIR` for testing.

- [ ] **Step 1: Write the scripts**

`scripts/seal-secret.sh`:

```bash
#!/usr/bin/env bash
# Seal one stack secret from stdin into SOPS. The value never touches argv,
# shell history or an unencrypted file outside a private tmpfs file.
set -euo pipefail

name=${1:?usage: seal-secret.sh <secret-file-name> < value}
root=$(git rev-parse --show-toplevel)
dir=${SECRETS_DIR:-$root/docker/stacks/n8n/secrets}
out=$dir/$name
sops=${SOPS:-sops}
recipients="age1y4x8gzzcdhxvqaf9matt0eze3z3yxwx607avq4cexfkgwal4psesj39lvn"
recipients+=",age1t405nrcjuavjg3u3qk65q2vnwkdm9zrc5j04xdk5kwl39kcucp5sscq8z6"

if [[ -e $out ]]; then
  echo "refusing to overwrite $out" >&2
  exit 1
fi

umask 077
tmp=$(mktemp -p "${XDG_RUNTIME_DIR:-/tmp}")
trap 'shred -u "$tmp" 2>/dev/null || rm -f "$tmp"' EXIT
cat >"$tmp"
if [[ ! -s $tmp ]]; then
  echo "empty value, nothing sealed" >&2
  exit 1
fi

"$sops" --encrypt --age "$recipients" \
  --input-type binary --output-type binary "$tmp" >"$out"
echo "sealed $out"
```

`scripts/new-wallet.sh`:

```bash
#!/usr/bin/env bash
# Create the fusion-signer wallet. The private key goes straight into SOPS;
# only the address is printed.
set -euo pipefail

here=$(cd "$(dirname "$0")/.." && pwd)
cd "$here"
node --input-type=module -e '
  import { Wallet } from "ethers";
  const w = Wallet.createRandom();
  process.stdout.write(w.privateKey);
  process.stderr.write(w.address + "\n");
' 2>"${XDG_RUNTIME_DIR:-/tmp}/fusion-signer-address" |
  "$here/scripts/seal-secret.sh" fusion-signer-key >/dev/null
echo "wallet address: $(cat "${XDG_RUNTIME_DIR:-/tmp}/fusion-signer-address")"
rm -f "${XDG_RUNTIME_DIR:-/tmp}/fusion-signer-address"
```

Make both executable:
`chmod +x docker/images/fusion-signer/scripts/*.sh`.

- [ ] **Step 2: Test with a fake sops that never sees a real secret**

Run from the repo root:

```bash
t=$(mktemp -d)
printf '#!/bin/sh\nfor a; do f=$a; done; printf "ENC:"; wc -c <"$f"\n' \
  >"$t/sops" && chmod +x "$t/sops"
cd docker/images/fusion-signer
out=$(SOPS="$t/sops" SECRETS_DIR="$t" nix shell nixpkgs#nodejs_22 -c \
  ./scripts/new-wallet.sh)
echo "$out"
echo "$out" | grep -Eq '^wallet address: 0x[0-9a-fA-F]{40}$' && echo ADDR_OK
grep -Eq '[0-9a-fA-F]{64}' <<<"$out" && echo LEAK || echo NO_KEY_ON_STDOUT
cat "$t/fusion-signer-key"
SOPS="$t/sops" SECRETS_DIR="$t" ./scripts/seal-secret.sh fusion-signer-key \
  </dev/null; echo "exit $?"
cd - && rm -rf "$t"
```

Expected: `ADDR_OK`, `NO_KEY_ON_STDOUT`, the key file contains `ENC:66`
(0x plus 64 hex chars), and the second seal prints
`refusing to overwrite` with `exit 1`.

- [ ] **Step 3: Commit**

```bash
git add docker/images/fusion-signer/scripts
git commit -m "feat(fusion-signer): add secret sealing and wallet scripts"
```

---

### Task 13: Stack service and README

**Prerequisite (blocking):** the user's MetaMask address in EIP-55
checksummed form. Ask for it if it is not in the conversation. Do not
invent one.

**Files:**

- Modify: `docker/stacks/n8n/docker-compose.yml` (new service, volume and
  secrets)
- Modify: `docker/stacks/n8n/README.md` (signer section)

**Interfaces:**

- Consumes: the image from Task 11; secret names from Global Constraints;
  scripts from Task 12.
- Produces: service `fusion-signer` reachable at
  `http://fusion-signer:8080` on the `n8n` overlay network, no published
  port, `DRY_RUN=true`.

- [ ] **Step 1: Add the service**

In `docker/stacks/n8n/docker-compose.yml`, add under `services:` after
`cloudflared` (replace `<METAMASK_ADDRESS>` with the user's checksummed
address before saving):

```yaml
fusion-signer:
  image: ghcr.io/soriphoono/fusion-signer:0.1.0
  environment:
    DRY_RUN: "true"
    MAX_ORDER_USD: "60"
    MAX_DAILY_USD: "150"
    DEFAULT_MAX_SLIPPAGE_BPS: "100"
    MIN_ORDER_INTERVAL_SEC: "60"
    ETH_GAS_RESERVE: "0.0003"
    WITHDRAW_ADDRESS: "<METAMASK_ADDRESS>"
  networks:
    - n8n
  read_only: true
  secrets:
    - fusion_signer_key
    - fusion_signer_token
    - oneinch_api_key
    - base_rpc_url
  volumes:
    - fusion_signer_data:/data
  deploy:
    placement:
      constraints:
        - node.hostname == sphoono-vps
    resources:
      limits:
        memory: 256M
    restart_policy:
      condition: any
      delay: 5s
```

Add `fusion_signer_data:` under `volumes:` and under `secrets:` add:

```yaml
fusion_signer_key:
  file: ./secrets/fusion-signer-key
fusion_signer_token:
  file: ./secrets/fusion-signer-token
oneinch_api_key:
  file: ./secrets/oneinch-api-key
base_rpc_url:
  file: ./secrets/base-rpc-url
```

- [ ] **Step 2: Validate the compose file**

Run:
`docker compose -f docker/stacks/n8n/docker-compose.yml config --quiet`
Expected: exit 0. (Missing secret files may be reported; that is expected
until the user seals them in Step 4.)

- [ ] **Step 3: Document the signer in the README**

Append to `docker/stacks/n8n/README.md`:

````markdown
## Fusion signer

`fusion-signer` holds the trading wallet key and places 1inch Fusion orders
on Base for n8n at `http://fusion-signer:8080`. It has no published port.
Design: `docs/superpowers/specs/2026-10-07-fusion-signer-design.md`.

Seal its secrets once, from the repo root, inside
`docker/images/fusion-signer` with dependencies installed
(`pnpm install`):

```sh
./scripts/new-wallet.sh            # prints only the wallet address
openssl rand -hex 32 | ./scripts/seal-secret.sh fusion-signer-token
./scripts/seal-secret.sh oneinch-api-key   # paste, then Ctrl-D
./scripts/seal-secret.sh base-rpc-url      # paste, then Ctrl-D
```

`DRY_RUN` stays `"true"` until the rail passes its test layers. Limits and
`WITHDRAW_ADDRESS` change only by editing this stack file.

To halt trading call `POST /halt`. To resume, remove the halt file on the
VPS: `docker exec <container> rm /data/halt`. Withdrawals still work while
halted.

Recovery without the signer: on a machine with the user's age key, run
`sops --decrypt docker/stacks/n8n/secrets/fusion-signer-key` and import the
key into MetaMask. Use this only when the signer or the VPS is gone.

The image is built by the `fusion-signer image` workflow and published to
`ghcr.io/soriphoono/fusion-signer`. Make the package public after the first
publish so the VPS can pull it.
````

- [ ] **Step 4: User seals the four secrets**

Hand off: the user runs the four commands from the README section (the
`new-wallet.sh` one prints the address; record it in Notion). Then confirm:

Run: `ls docker/stacks/n8n/secrets/`
Expected: `fusion-signer-key`, `fusion-signer-token`, `oneinch-api-key`,
`base-rpc-url` present, each a JSON file with a `sops` block. Never open
them.

- [ ] **Step 5: Commit**

```bash
git add docker/stacks/n8n/docker-compose.yml docker/stacks/n8n/README.md \
  docker/stacks/n8n/secrets/fusion-signer-key \
  docker/stacks/n8n/secrets/fusion-signer-token \
  docker/stacks/n8n/secrets/oneinch-api-key \
  docker/stacks/n8n/secrets/base-rpc-url
git commit -m "feat(n8n-stack): add fusion-signer service and secrets"
```

Expected: gitleaks passes (values are encrypted).

---

### Task 14: Layer 2, local dry-run quotes

**Files:** none (verification only).

**Interfaces:**

- Consumes: `dist/quote-check.js` (Task 10).

- [ ] **Step 1: User runs the probe with their keys**

Hand off; the user runs, from `docker/images/fusion-signer`:

```bash
read -rs ONEINCH_API_KEY; read -rs BASE_RPC_URL
ONEINCH_API_KEY=$ONEINCH_API_KEY BASE_RPC_URL=$BASE_RPC_URL \
  nix shell nixpkgs#nodejs_22 -c node dist/quote-check.js
```

Expected: six lines (`BTC`/`ETH` at `$5`, `$25`, `$50`), each with a worst
price and bps.

- [ ] **Step 2: Judge the result**

Pass: every line has a quote and at most 100 bps. If $5 has no quote or
exceeds 100 bps while $25 and $50 pass, use $25 for the layer-4 round
trips and record that in Notion. If $25 fails, stop and report: the spec's
fallback (1inch classic swap API) needs its own design.

---

### Task 15: n8n objects (after the user deploys)

**Prerequisites:** the branch is merged and deployed by the user;
`fusion-signer` logs `listening` with `dryRun: true`; the user created the
Header Auth credential "Fusion Signer" (`Authorization`,
`Bearer <token>`) in the n8n UI. Follow the n8n MCP rules: read the SDK
reference and node types before writing workflow code, validate, create,
then read back.

**Files:** none in git (n8n objects). Record IDs in Notion and in
`~/Shared/trading/AGENTS.md`.

- [ ] **Step 1: Create the ledger table**

Use `create_data_table` in project `e7eqvN6WhKvrtMAt`, name
`crypto_trend_live_ledger`, string columns `request_id`, `ts`, `source`,
`symbol`, `side`, `request_amount`, `order_hash`, `status`,
`refusal_reason`, `sell_token`, `sell_amount`, `buy_token`, `buy_amount`,
`tx_hash`, `destination`; number columns `max_slippage_bps`,
`effective_price`, `ref_price`, `slippage_bps`; boolean `dry_run`.
Read it back with `search_data_tables`.

- [ ] **Step 2: Build "Fusion Rail Test"**

Nodes (manual trigger only, never published):

1. `Manual Trigger`.
2. `Params` (Code): returns
   `{ mode: "quote", side: "buy", asset: "BTC", amount: { usdc: "5.00" },
maxSlippageBps: 100 }` with a comment that `mode` is
   `status | quote | order`.
3. `Get Status` (HTTP GET `http://fusion-signer:8080/status`, Header Auth
   "Fusion Signer", retry 3, wait 5000 ms).
4. `Quote` (HTTP POST `/quote`, JSON body
   `{{ JSON.stringify({ side, asset, amount }) }}` from `Params`, retry 3,
   response options `neverError: true`, `fullResponse: true`).
5. `Is Order?` (IF `{{ $('Params').item.json.mode }}` equals `order`).
6. `Place Order` (HTTP POST `/orders`, body adds
   `requestId: "test-" + $execution.id` and `maxSlippageBps`, no retry,
   `neverError: true`, `fullResponse: true`).
7. `Wait 20s` (Wait node, 20 seconds).
8. `Get Order` (HTTP GET `/orders/{{ orderHash }}`, retry 3).
9. `Done?` (Code): terminal when `status` is `filled`, `expired` or
   `cancelled`, or `$runIndex >= 17` (6 minutes); outputs `{ done }`.
10. `Loop` (IF `done` is false → back to `Wait 20s`).
11. `Ledger Row` (Code): one row with `source: "test"` built from Params,
    the order reply (status code 403 → `status: "refused"`,
    `refusal_reason`) and the final order status (`sell_amount`,
    `buy_amount`, `effective_price`, `ref_price`, `slippage_bps`).
12. `Record` (Data table insert into `crypto_trend_live_ledger`).
13. `Telegram` (credential "Telegram - Arduin Bot", chat `8925872516`,
    HTML): requested, outcome, fill vs Coinbase.

Settings: `errorWorkflow` `reVnFV9ksMWtWvVu`. Validate, create, read back.

- [ ] **Step 3: Build "Fusion Withdraw"**

Nodes (manual trigger only):

1. `Manual Trigger`.
2. `Params` (Code): `{ asset: "USDC", amount: { units: "1.00" } }`, comment
   that `amount` may be `{ all: true }` and `asset` is
   `USDC | BTC | ETH | GAS`.
3. `Get Status` (HTTP GET `/status`).
4. `Withdraw` (HTTP POST `/withdraw`, body
   `{ requestId: "withdraw-" + $execution.id, asset, amount }`, no retry,
   `neverError: true`, `fullResponse: true`).
5. `Ledger Row` (Code): `source: "withdraw"`, `side: "withdraw"`,
   `tx_hash`, `destination`, `status`, `refusal_reason`.
6. `Record` (Data table insert).
7. `Telegram`: amount, destination and
   `https://basescan.org/tx/<tx_hash>`.

Settings: `errorWorkflow` `reVnFV9ksMWtWvVu`. Validate, create, read back.

- [ ] **Step 4: Layer 3, VPS dry run**

Run "Fusion Rail Test" with `mode: "status"`, then `"quote"`, then
`"order"`. Expected: status shows the wallet and `dryRun: true`; the quote
returns prices; the order returns 403 `insufficient_balance` (empty
wallet) and a ledger row plus Telegram message with `status: refused`.
Read the execution back with `get_workflow_execution`.

---

### Task 16: Layers 4 to 6, small real money (user-driven)

**Files:** `docker/stacks/n8n/docker-compose.yml` (only `DRY_RUN`).

- [ ] **Step 1: User funds the wallet**

The user sends about $10 USDC and about $1 of ETH on Base to the wallet
address. Confirm with "Fusion Rail Test" `mode: "status"`.

- [ ] **Step 2: Turn dry run off**

Change `DRY_RUN: "true"` to `DRY_RUN: "false"`, commit
`feat(n8n-stack): enable fusion-signer live mode for rail tests`. The user
merges and deploys.

- [ ] **Step 3: Approve and round trip cbBTC**

Call `POST /approve {"asset":"USDC"}` (add a temporary `approve` mode to
"Fusion Rail Test" or run it from the n8n UI), then run "Fusion Rail Test"
`order` buy BTC `{ usdc: "5.00" }`; after it fills, approve `BTC` and sell
`{ fraction: 1 }`. Expected: both legs `filled`, cost per side at most
30 bps against Coinbase (from `slippage_bps` and `effective_price`).

- [ ] **Step 4: Round trip WETH**

Same as Step 3 with `asset: "ETH"`.

- [ ] **Step 5: Layer 5 refusals**

Run an order of `{ usdc: "61" }` (expect 403 `order_cap`), repeat an
execution's `requestId` by re-sending the same body (expect the stored
result), call `POST /halt` (expect orders to return 423), then the user
runs `docker exec <container> rm /data/halt` and an order works again.

- [ ] **Step 6: Layer 6 withdrawal**

Run "Fusion Withdraw" with `asset: "USDC"`, `amount: { all: true }`.
Expected: `sent`, a Basescan link, and the user confirms the USDC arrived
in MetaMask. Re-run with the same body via the same `requestId` and
expect the stored result.

- [ ] **Step 7: Close out**

Check that the signer logs carry only the expected fields (the user runs
this on the VPS):

```bash
docker service logs --raw n8n_fusion-signer 2>&1 |
  jq -c 'keys' | sort -u
```

Expected: only key sets drawn from `ts`, `method`, `path`, `status`,
`reason`, `requestId`, `orderHash`, `ms`, `event`, `port`, `address`,
`dryRun` and `error`, and any `error` text contains no key material
(`[redacted]` where a secret was).

Then set `DRY_RUN` back to `"true"` until "Crypto Trend Live" exists,
commit, and record the measured cost per side and fill times in Notion.
