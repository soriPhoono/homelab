# Fusion signer: live execution rail for the crypto trend bot

- Date: 2026-10-07
- Status: design approved in conversation; written spec awaiting review
- Related: `~/Shared/trading` (strategy, backtests, n8n sources) and the
  Notion page "Crypto Trading applications"

## 1. Purpose and scope

The crypto trend bot (n8n workflow `g5xGQD25tJ3Mj5sS`) trades BTC and ETH on
paper with a daily SMA 50/100/200 blend. This spec covers the real-money
execution rail it will use once the strategy has proven itself on paper. The
rail is built and tested now; it is not connected to the trend bot.

In scope:

- `fusion-signer`: a service in the n8n Swarm stack that holds the wallet key
  and places 1inch Fusion orders on Base, behind hard limits.
- n8n: one credential, one ledger table and two manual-only workflows
  ("Fusion Rail Test" and "Fusion Withdraw").
- Withdrawals to the user's MetaMask address, which is fixed in config.
- A wallet-generation script that writes the key straight into SOPS, and a
  documented recovery path that does not need the signer.

Out of scope until the paper strategy is proven:

- The "Crypto Trend Live" workflow (section 6.5 describes it so the rail fits).
- Funding beyond the test amount.

Success means the rail executes small real swaps in both directions for both
coins, records the fills, refuses everything outside its limits and never
exposes the key.

## 2. Decisions

- **Venue:** Base, 1inch Fusion (intent swaps). User choice. Resolvers pay
  gas, and the Dutch auction limits MEV.
- **Smart contract:** none. Fusion orders are EIP-712 signatures from an
  ordinary wallet; only token approvals are on-chain.
- **Signer location:** the VPS `sphoono-vps`, in the same Swarm stack as n8n.
  User choice. Internal overlay network, no published port.
- **Secret delivery:** Docker Swarm secrets created from SOPS files and read at
  `/run/secrets/*`. User choice. Matches the existing stack (Swarm-CD with
  `sops_secrets_discovery`). Never environment variables.
- **Who decides, who signs:** n8n decides asset, side and amount; the signer
  only validates and executes. Strategy logic stays in n8n, where harnesses
  test it, and the signer stays small.
- **Rejected, signing in the n8n runners:** the runners execute every
  workflow's Code nodes, so any of them could read the key.
- **Rejected, a generic "sign this" service:** signing arbitrary typed data
  allows permit-style drains.
- **Budget:** $100, a $50 sleeve per coin, plus about $1 of ETH for approvals
  and transfers. User choice.
- **Withdrawals:** one fixed destination, the user's MetaMask address
  (`WITHDRAW_ADDRESS`). No request can name another address, so a stolen
  bearer token can at worst move funds to the user.
- **Profit sweep:** after a live sell that realizes a gain, n8n sends
  `SWEEP_SHARE` (default 20%) of that gain in USDC to the MetaMask address. The
  rest compounds in the sleeve. User choice.

## 3. Architecture

```text
n8n (overlay net "n8n")            fusion-signer (same stack, no port)
+---------------------------+      +---------------------------------+
| "Fusion Rail Test"        | ---> | HTTP API :8080                  |
| later "Crypto Trend Live" | <--- | guard -> Fusion SDK -> ethers   |
+---------------------------+      | /run/secrets/*, state in /data  |
     Bearer token, JSON            +----------------+----------------+
                                                    |
                    1inch Fusion API, Base RPC, Coinbase ticker
```

### 3.1 Repository layout (homelab)

- `docker/images/fusion-signer/`: TypeScript service, `package.json`,
  lockfile, `Dockerfile` and vitest tests.
- `docker/images/fusion-signer/scripts/new-wallet.sh`: wallet generation into
  SOPS.
- `.github/workflows/fusion-signer-image.yml`: test, build and publish
  `ghcr.io/soriphoono/fusion-signer:<version>` as a public package, like
  `n8n-runners`.
- `docker/stacks/n8n/docker-compose.yml`: the new `fusion-signer` service, its
  secrets and the `fusion_signer_data` volume.
- `docker/stacks/n8n/secrets/`: SOPS-encrypted secret files, added by the
  user.
- `docker/stacks/n8n/README.md`: secret setup and wallet generation.

### 3.2 Runtime

- Node 22, `@1inch/fusion-sdk`, `ethers` v6 and Node's `http` module (or
  `fastify`). Pinned versions and a lockfile.
- Runs as a non-root user with a read-only root filesystem; only `/data` is
  writable.
- Placement `node.hostname == sphoono-vps`, memory limit 256M, restart `any`.
- The healthcheck calls `GET /health` inside the container.

### 3.3 Secrets

Each Swarm secret comes from a SOPS file in `docker/stacks/n8n/secrets/`:

- `fusion_signer_key` (`fusion-signer-key`): the wallet private key, for a
  dedicated wallet, never a personal one.
- `fusion_signer_token` (`fusion-signer-token`): the bearer token n8n must
  send, generated with `openssl rand -hex 32`.
- `oneinch_api_key` (`oneinch-api-key`): the 1inch Dev Portal API key.
- `base_rpc_url` (`base-rpc-url`): the Base RPC URL, which often embeds a
  provider key.

The service reads each file once at start, trims whitespace and refuses to
start if any is missing or empty. No secret value is ever logged, returned or
put in an error message.

### 3.4 Non-secret configuration

Environment variables in the compose file:

- `DRY_RUN`, default `true`: when true, nothing is signed or submitted.
- `MAX_ORDER_USD`, default `60`: per-order cap.
- `MAX_DAILY_USD`, default `150`: cap on submitted notional per UTC day.
- `DEFAULT_MAX_SLIPPAGE_BPS`, default `100`: worst-case fill against the
  reference price.
- `MIN_ORDER_INTERVAL_SEC`, default `60`: minimum gap between orders for one
  asset.
- `WITHDRAW_ADDRESS`, required: the user's MetaMask address. The service
  refuses to start if it is missing, fails the EIP-55 checksum, or equals the
  signer's own address. It is public, so it lives in git.
- `FUSION_SETTLEMENT_ADDRESS`, required: the 1inch Fusion settlement
  extension contract on Base, verified on Basescan by the user (`quote-check`
  prints the one 1inch returns). The service refuses to start if it is
  missing or fails the EIP-55 checksum, and refuses any order whose
  `settlementExtensionContract` differs (`order_mismatch`), because that
  contract governs the order's real economics. It is public, so it lives in
  git.
- `ETH_GAS_RESERVE`, default `0.0003`: ETH kept back by a partial ETH
  withdrawal so the wallet can still pay for approvals and transfers.

Changing a limit or the withdrawal address is a commit to the compose file and
a deploy. No API changes them.

### 3.5 Tokens

Base, chain id 8453. Hardcoded:

- Cash, USDC: `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913`, 6 decimals.
- BTC, cbBTC: `0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf`, 8 decimals.
- ETH, WETH: `0x4200000000000000000000000000000000000006`, 18 decimals.
- Approval target, 1inch Limit Order Protocol v4:
  `0x111111125421cA6dc452d289314280a0f8842A65`.

Look-alike tokens named "cbBTC" exist at other addresses. Requests never carry
addresses, so they cannot substitute one. The service reads decimals on-chain
at start and refuses to start if they differ from this list. The addresses are
re-checked on Basescan before the first real swap.

## 4. API

Bodies are JSON, and unknown fields are rejected (400). Every endpoint except
`/health` requires `Authorization: Bearer <fusion_signer_token>`, compared in
constant time (401 otherwise). Requests name an asset (`BTC` or `ETH`) and a
side (`buy` is USDC to asset, `sell` is asset to USDC). They never carry token
addresses.

- `GET /health`, no auth: returns `{ "ok": true }`.
- `GET /status`: address, chain id, balances of ETH, USDC, cbBTC and WETH (raw
  and decimal), allowances to the v4 contract, active limits, today's
  submitted notional, `dryRun`, `halted` and version.
- `POST /quote` with `{ side, asset, amount }`: auction start and end
  (worst-case) amounts, implied prices, the Coinbase reference price and the
  worst-case slippage in bps. Never signs.
- `POST /orders` with `{ requestId, side, asset, amount, maxSlippageBps? }`:
  runs the guard (section 5), then signs and submits. Returns
  `{ requestId, orderHash, status: "pending" }`. In dry run it returns
  `{ status: "dry_run", quote, order }` and signs nothing.
- `GET /orders/:hash`: `status` (`pending`, `filled`, `expired` or
  `cancelled`), fills, amounts sold and bought, and the effective price.
- `POST /approve` with `{ asset }` (`USDC`, `BTC` or `ETH`): approves the v4
  contract for an amount worth at most `MAX_DAILY_USD` and returns the
  transaction hash. Spends gas. Respects `DRY_RUN`.
- `POST /withdraw` with `{ requestId, asset, amount }`: transfers to
  `WITHDRAW_ADDRESS` and returns the transaction hash (section 5.1). `asset`
  is `USDC`, `BTC`, `ETH` (WETH) or `GAS` (native ETH). Spends gas. Respects
  `DRY_RUN`. Allowed while halted.
- `POST /halt` with `{ reason }`: writes `/data/halt` and returns
  `{ halted: true }`. No endpoint removes it; the user deletes the file on the
  VPS to resume.

`amount` formats:

- Buy: `{ "usdc": "25.00" }`.
- Sell: `{ "units": "0.000291" }`, or `{ "fraction": 1 }` for a share of the
  current balance (0 < f <= 1).
- Withdraw: `{ "units": "12.50" }` or `{ "all": true }`.

`requestId` is 1 to 64 characters from `[A-Za-z0-9._:-]`.

## 5. Guard

`POST /orders` runs these checks in order:

1. Not halted (`/data/halt` absent), else 423 `halted`.
2. Body valid, known asset and side, else 400.
3. Known `requestId`: the same body returns the stored result; a different body
   returns 409 `request_id_conflict`.
4. Notional in USD at the Coinbase reference price is at most `MAX_ORDER_USD`,
   else 403 `order_cap`.
5. Today's submitted notional plus this order is at most `MAX_DAILY_USD` (UTC
   day), else 403 `daily_cap`.
6. The last order for this asset was at least `MIN_ORDER_INTERVAL_SEC` ago,
   else 403 `too_soon`.
7. The wallet balance covers the sell amount, else 403 `insufficient_balance`.
8. The allowance to the v4 contract covers the sell amount, else 403
   `insufficient_allowance`.
9. The quote's worst-case (auction end) price is within `maxSlippageBps` of the
   Coinbase reference, else 403 `slippage`.
10. The built order has maker equal to the signer's address, receiver equal to
    that address (or zero, meaning the maker) and maker and taker assets that
    match the request, else 403 `order_mismatch`.
11. If `DRY_RUN`, return 200 `dry_run` without signing.
12. Record the notional against the day, then sign and submit. Upstream errors
    return 502 and are recorded.

The reference price is Coinbase's public ticker for `BTC-USD` or `ETH-USD`,
the source the strategy uses. 1inch's quote is never its own reference. If the
ticker cannot be fetched, the order is refused with 403 `no_reference`.

State lives in `/data` as JSON files written atomically: the request log
(requestId to body hash and result), notional per UTC date, last order time
per asset and the halt flag. The signer never retries a submit itself; a
caller retry with the same `requestId` returns the stored result.

### 5.1 Withdraw guard

`POST /withdraw` runs these checks in order. The trade caps (4 to 6 above) do
not apply, because the destination is always the user.

1. Body valid, known asset, else 400.
2. Known `requestId`: same rule as orders (stored result or 409).
3. The destination is `WITHDRAW_ADDRESS` from config; the body has no address
   field.
4. The amount is greater than zero and covered by the balance, else 403
   `insufficient_balance`. For `GAS`, `{ "units" }` must leave
   `ETH_GAS_RESERVE`, else 403 `gas_reserve`; `{ "all": true }` sends
   everything except the gas for this transfer.
5. Enough ETH for the transfer's gas, else 403 `no_gas`.
6. If `DRY_RUN`, return 200 `dry_run` with the transfer it would send.
7. Send an ERC-20 `transfer` (or a native transfer for `GAS`), record it and
   return the transaction hash.

Halt does not block withdrawals, so "halt, then withdraw everything" is the
emergency exit.

Errors: 400 invalid body, 401 auth, 403 guard refusal with a `reason` code,
409 request id conflict, 423 halted, 502 upstream failure (1inch, RPC or
Coinbase). Logs are one JSON line per request with requestId, endpoint,
status, reason and order hash, never secrets.

## 6. n8n

### 6.1 Credential

Header Auth credential "Fusion Signer": `Authorization` set to
`Bearer <fusion-signer-token>`. The user creates it in the n8n UI, so the
token never passes through workflow code or the MCP.

### 6.2 Table `crypto_trend_live_ledger`

- Identity: `request_id`, `ts`, `source` (`test`, `trend`, `sweep` or
  `withdraw`), `symbol`, `side` (`buy`, `sell` or `withdraw`), `dry_run`.
- Withdrawals: `tx_hash`, `destination`.
- Request: `request_amount`, `max_slippage_bps`.
- Result: `order_hash`, `status` (`dry_run`, `pending`, `filled`, `expired`,
  `refused` or `error`), `refusal_reason`.
- Fill: `sell_token`, `sell_amount`, `buy_token`, `buy_amount`,
  `effective_price`, `ref_price`, `slippage_bps`.

### 6.3 Workflow "Fusion Rail Test"

Built with the rail. Manual trigger only; never activated or scheduled.

```text
Manual Trigger
  -> Set Params {mode: status|quote|order, side, asset,
                 amount, maxSlippageBps}
  -> GET /status -> POST /quote
  -> if mode = order: POST /orders {requestId: "test-<executionId>"}
       -> poll GET /orders/:hash every 20 s, up to 6 min
  -> insert row into crypto_trend_live_ledger
  -> Telegram summary to Arduin
```

GET calls retry 3 times. `POST /orders`, `POST /approve` and `POST /withdraw`
never retry automatically. Refusals and errors are recorded and sent to
Telegram. The `errorWorkflow` is the existing Error Alert workflow
(`reVnFV9ksMWtWvVu`).

### 6.4 Workflow "Fusion Withdraw"

Built with the rail. Manual trigger only.

```text
Manual Trigger
  -> Set Params {asset: USDC|BTC|ETH|GAS, amount: units or all}
  -> GET /status (shows balances and the destination)
  -> POST /withdraw {requestId: "withdraw-<executionId>"}
  -> insert row (source "withdraw") into crypto_trend_live_ledger
  -> Telegram receipt to Arduin with the Basescan link
```

### 6.5 Later: "Crypto Trend Live"

Not built in this phase. A copy of the trend bot whose decision step calls the
rail; the paper bot keeps running.

- Sleeve sizing comes from filled rows in the live ledger, cross-checked
  against `/status` balances. A mismatch above 1% halts trading and alerts.
- `requestId` is `<bar_date>-<symbol>-<attempt>`.
- An expired order is retried with a fresh quote on the next hourly run. After
  3 expiries for one decision it alerts and holds.
- Profit sweep: when a sell fills, n8n computes the realized gain in USDC
  against the sleeve's cost basis. If the gain is positive, it withdraws
  `SWEEP_SHARE` of it (default 0.2, a constant in the workflow) as USDC with
  `requestId` `<sell requestId>-sweep` and records a `sweep` row that lowers
  the sleeve's cash. Losses sweep nothing and are not topped up. Sweeps under
  `MIN_SWEEP_USD` (default 1) are skipped so gas does not eat them.

## 7. Wallet generation

`scripts/new-wallet.sh` creates a random wallet and pipes the private key
directly into `sops --encrypt` for
`docker/stacks/n8n/secrets/fusion-signer-key`. It prints only the address. The
key never appears on screen, in shell history or in an agent session. The user
runs it.

Recovery without the signer: the user holds the age key, so
`sops --decrypt docker/stacks/n8n/secrets/fusion-signer-key` on their own
machine gives the private key, which can be imported into MetaMask to move
everything out. The stack README documents this as the last resort for when
the signer or the VPS is unavailable.

## 8. Testing

Each layer must pass before the next.

1. Unit tests (vitest), run in CI before the image is published. $0. Every
   guard check refuses what it should; idempotency; decimals for 6, 8 and 18;
   `order_mismatch` on a tampered order; slippage maths; withdrawals always go
   to `WITHDRAW_ADDRESS` and keep the gas reserve; start-up refuses a bad or
   self-referencing `WITHDRAW_ADDRESS`. 1inch, the RPC and Coinbase are
   mocked.
2. Local dry run against the real Base RPC and 1inch API, with an empty
   throwaway wallet. $0. Quotes for $5, $25 and $50 exist and fall within 1%
   of Coinbase, which answers the Fusion minimum-size question.
3. VPS dry run through "Fusion Rail Test". $0. Secrets, network, credential,
   ledger and Telegram path.
4. Real round trips: fund about $10 USDC and $1 ETH, approve USDC, buy $5 of
   cbBTC, approve cbBTC, sell it; the same for WETH. About $10 at risk. Real
   fills, fill time and cost per side against Coinbase.
5. Live refusals: a $61 order, a reused requestId, and halt followed by a
   manual resume. $0. The limits hold in production.
6. Withdrawal: "Fusion Withdraw" sends the leftover test USDC to MetaMask, then
   a reused requestId returns the stored result. Cents of gas. The user
   confirms the funds arrived in MetaMask.

Exit criteria:

- All four round-trip legs fill, and the withdrawal arrives in MetaMask.
- Cost per side is at most 0.3% against the Coinbase reference. The backtest
  assumes 0.175%, and `bt3.py` holds at 4x costs.
- Every layer-5 refusal behaves as specified.
- No secret appears in the logs.

The $100 is funded only after the paper strategy is proven and "Crypto Trend
Live" exists.

## 9. Rollout

Branch `feat/fusion-signer` from `origin/dev`, one logical change per commit:

1. `docs: add fusion-signer execution rail design spec` (this file).
2. `feat(fusion-signer): add Fusion signer service with guard and tests`.
3. `ci: build and publish fusion-signer image`.
4. `feat(n8n-stack): add fusion-signer service and secrets (DRY_RUN=true)`;
   the user adds the encrypted secret files.
5. `docs(n8n-stack): document signer secrets and wallet generation`.

Swarm-CD deploys from `main`, so the signer reaches the VPS when `dev` is
merged into `main`. The user deploys. The n8n objects (credential, table and
the two manual workflows) are created after deployment.

## 10. Risks

- **Resolvers ignore $5 to $50 orders on Base.** Layer 2 measures this before
  any money moves. Fallback: the 1inch classic swap API, where the signer pays
  gas (cents on Base).
- **Fusion's MEV benefit is smaller on Base,** which has a single sequencer and
  no public mempool. Accepted; the slippage guard bounds the worst case.
- **Root on the VPS can read the key.** Small balance, approvals capped at
  `MAX_DAILY_USD`, a dedicated wallet and the halt switch.
- **1inch or RPC outage on a decision day.** Orders fail closed; the live
  workflow retries next hour and alerts after 3 failures.
- **Coinbase reference unavailable.** Orders are refused (`no_reference`).
- **Wrong token contract.** Hardcoded addresses, decimals verified at start and
  a Basescan check before the first real swap.
- **Wrong withdrawal address in config.** EIP-55 checksum check at start, and
  the first withdrawal is the small layer-6 test that the user confirms in
  MetaMask.
- **Signer or VPS lost with funds inside.** Decrypt the key with the user's age
  key and import it into MetaMask (section 7).
