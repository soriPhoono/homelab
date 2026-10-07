/**
 * Chain constants, the token allowlist and unit conversion.
 *
 * Requests never carry token addresses: they name an asset ("BTC", "ETH") and
 * the service maps it to the hardcoded contract here. That is what stops a
 * request from swapping into a look-alike token.
 */
import { formatUnits, parseUnits } from "ethers";

/** A tradable asset as named in requests. BTC means cbBTC, ETH means WETH. */
export type Asset = "BTC" | "ETH";

/** Any ERC-20 the signer holds: the cash leg (USDC) plus the two assets. */
export type TokenKey = "USDC" | Asset;

/**
 * Anything that can be withdrawn: the three ERC-20s plus "GAS", which is the
 * wallet's native ETH (used to pay for approvals and transfers).
 */
export type Holding = TokenKey | "GAS";

/** One allowlisted ERC-20 on Base. */
export interface Token {
  /** Name used in requests and in `TOKENS`. */
  key: TokenKey;
  /** On-chain symbol, shown in responses (e.g. "cbBTC"). */
  symbol: string;
  /** Contract address on Base, EIP-55 checksummed. */
  address: string;
  /** ERC-20 decimals; checked against the chain at startup (startup.ts). */
  decimals: number;
}

/** Base mainnet chain id. startup.ts refuses to run against any other chain. */
export const CHAIN_ID = 8453;

/**
 * 1inch Limit Order Protocol v4, the contract Fusion orders settle through.
 * It is the only spender the signer ever approves (Service.approve) and the
 * spender whose allowance the guard checks before an order.
 */
export const LOP_V4 = "0x111111125421cA6dc452d289314280a0f8842A65";

/**
 * The token allowlist, keyed by the names requests use. Addresses are the
 * canonical Base contracts; look-alike tokens with the same symbol exist at
 * other addresses, which is why they are hardcoded rather than looked up.
 */
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

/**
 * Coinbase product for each asset's USD reference price (reference.ts). It
 * is the same price source the trading strategy uses.
 */
export const COINBASE_PRODUCT: Record<Asset, string> = {
  BTC: "BTC-USD",
  ETH: "ETH-USD",
};

/**
 * Decimal string -> raw integer units, e.g. toRaw("25.00", 6) = 25000000n.
 * Throws if `amount` has more decimals than the token (callers turn that
 * into a 400).
 */
export const toRaw = (amount: string, decimals: number): bigint =>
  parseUnits(amount, decimals);

/**
 * Raw integer units -> decimal string,
 * e.g. fromRaw(29100n, 8) = "0.000291".
 */
export const fromRaw = (raw: bigint, decimals: number): string =>
  formatUnits(raw, decimals);

/**
 * Find an allowlisted token by contract address (case-insensitive), or
 * `undefined` if the address is not one of ours. Used to interpret the
 * maker/taker assets reported back by 1inch (Service.orderStatus).
 */
export const tokenByAddress = (address: string): Token | undefined =>
  Object.values(TOKENS).find(
    (t) => t.address.toLowerCase() === address.toLowerCase(),
  );
