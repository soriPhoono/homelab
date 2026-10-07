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
