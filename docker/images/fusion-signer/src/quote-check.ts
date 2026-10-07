/**
 * Testing layer 2: a one-off probe run by the user on their own machine
 * (`node dist/quote-check.js`), never by the service.
 *
 * It answers two questions before any money is involved:
 * 1. Does 1inch Fusion quote $5, $25 and $50 USDC buys of cbBTC and WETH
 *    on Base, and how far is each worst case from the Coinbase price?
 * 2. Which settlement contract does 1inch use? It prints the address for
 *    the user to verify on Basescan and then set as
 *    FUSION_SETTLEMENT_ADDRESS.
 *
 * It uses a freshly generated, never-funded wallet and never submits an
 * order. Printed errors have the API key and RPC URL redacted.
 */
import { JsonRpcProvider, Wallet } from "ethers";
import { redact } from "./errors.js";
import { FusionClient } from "./adapters/fusion-client.js";
import { slippageBps, unitPrice } from "./guard.js";
import { makeReference } from "./reference.js";
import { CHAIN_ID, TOKENS, toRaw, type Asset } from "./tokens.js";

// Needs ONEINCH_API_KEY and BASE_RPC_URL in the environment.
const { ONEINCH_API_KEY, BASE_RPC_URL } = process.env;
if (!ONEINCH_API_KEY || !BASE_RPC_URL) {
  throw new Error("set ONEINCH_API_KEY and BASE_RPC_URL");
}
/** Read-only Base connection, pinned to chain id 8453. */
const provider = new JsonRpcProvider(BASE_RPC_URL, CHAIN_ID, {
  staticNetwork: true,
});
const wallet = Wallet.createRandom(); // empty, never funded
/** 1inch client bound to the throwaway wallet. */
const fusion = new FusionClient(
  wallet.address,
  wallet.privateKey,
  provider,
  ONEINCH_API_KEY,
);
/** Coinbase reference prices, the same source the service uses. */
const reference = makeReference();

// Question 1: quote each size for each asset and print the worst case.
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
      console.log(
        `${asset} $${usd}: no quote (${redact((err as Error).message, [
          ONEINCH_API_KEY,
          BASE_RPC_URL,
        ])})`,
      );
    }
  }
}

// Question 2: which settlement contract an order would be bound to.
// Build only, never submit: the throwaway wallet signs nothing and holds nothing.
try {
  const built = await fusion.build(
    TOKENS.USDC.address,
    TOKENS.ETH.address,
    toRaw("5", 6),
  );
  console.log(
    "settlement contract (verify on Basescan before setting " +
      `FUSION_SETTLEMENT_ADDRESS): ${built.summary.settlement}`,
  );
} catch (err) {
  console.log(
    `settlement contract: no order (${redact((err as Error).message, [
      ONEINCH_API_KEY,
      BASE_RPC_URL,
    ])})`,
  );
}
