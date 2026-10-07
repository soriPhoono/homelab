/**
 * Checks run once at startup, before the server listens. Any failure stops
 * the process (main.ts logs it and exits 1), so the signer never runs
 * against the wrong chain, the wrong token contracts, or a withdrawal
 * address that is its own wallet.
 */
import { assertNotSelf, type Config } from "./config.js";
import type { Chain } from "./ports.js";
import { CHAIN_ID, TOKENS } from "./tokens.js";

/**
 * Verify the environment against what the code assumes:
 * 1. The RPC reports Base (chain id 8453).
 * 2. Every allowlisted token reports the decimals hardcoded in `TOKENS`
 *    (catches a wrong address or a misbehaving RPC).
 * 3. WITHDRAW_ADDRESS is not the signer's own address.
 */
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
