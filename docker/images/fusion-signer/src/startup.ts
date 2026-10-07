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
