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
      console.log(
        `${asset} $${usd}: no quote (${redact((err as Error).message, [
          ONEINCH_API_KEY,
          BASE_RPC_URL,
        ])})`,
      );
    }
  }
}

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
