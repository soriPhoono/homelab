/**
 * The two boundaries between the service and the outside world.
 *
 * `Chain` covers the wallet and Base RPC; `Fusion` covers the 1inch Fusion
 * API. The service depends only on these interfaces. Production wires in the
 * real adapters (adapters/ethers-chain.ts, adapters/fusion-client.ts); tests
 * wire in fakes (test/fakes.ts), so every rule can be tested without a
 * network or a key.
 *
 * Addresses are hex strings; token amounts are raw integer units (bigint).
 */

/** The signer's wallet on Base. Write methods return a transaction hash. */
export interface Chain {
  /** The wallet's own address (derived from the private key). */
  readonly address: string;
  /** Chain id the RPC reports; must be Base (startup.ts). */
  chainId(): Promise<number>;
  /** ERC-20 decimals of `token`, read on-chain (startup.ts). */
  decimals(token: string): Promise<number>;
  /** The wallet's balance of ERC-20 `token`. */
  balance(token: string): Promise<bigint>;
  /** The wallet's native ETH balance in wei (pays for gas). */
  ethBalance(): Promise<bigint>;
  /** How much of `token` `spender` may move from the wallet. */
  allowance(token: string, spender: string): Promise<bigint>;
  /** Send an ERC-20 approve transaction. Spends gas. */
  approve(token: string, spender: string, amount: bigint): Promise<string>;
  /** Send an ERC-20 transfer. Spends gas. */
  transfer(token: string, to: string, amount: bigint): Promise<string>;
  /** Send native ETH. Spends gas. */
  sendEth(to: string, amount: bigint): Promise<string>;
  /** Wei for one transfer of this kind, with margin. */
  gasCost(kind: "erc20" | "eth"): Promise<bigint>;
}

/**
 * The fields of a built (not yet signed) Fusion order that the guard checks.
 * They come from the exact order object that `BuiltOrder.submit` signs.
 */
export interface OrderSummary {
  /** Order hash, computed locally before submission. */
  hash: string;
  /** Wallet that gives up `makerAsset`; must be the signer. */
  maker: string;
  /** Where the funds actually go (the SDK's realReceiver). */
  receiver: string;
  /** The 1inch settlement extension contract the order is bound to. */
  settlement: string;
  /** Token the signer sells. */
  makerAsset: string;
  /** Token the signer receives. */
  takerAsset: string;
  /** Amount of `makerAsset` sold, raw units. */
  makingAmount: bigint;
  /** Minimum received at the end of the auction. */
  takingAmount: bigint;
}

/**
 * An order ready to sign. The service checks `summary` with the guard and
 * only then calls `submit`, so what is checked is what gets signed.
 */
export interface BuiltOrder {
  summary: OrderSummary;
  /** Signs and submits; resolves to the order hash. */
  submit(): Promise<string>;
}

/**
 * Output amounts of a 1inch quote's Dutch auction, raw units of the token
 * bought: the best case at auction start and the worst case at the end.
 */
export interface QuoteSummary {
  startAmount: bigint;
  endAmount: bigint;
}

/** One on-chain fill of an order (an order can fill in several parts). */
export interface FusionFill {
  /** Transaction that performed the fill. */
  txHash: string;
  /** Amount of the maker asset sold in this fill, raw units. */
  makerAmount: bigint;
  /** Amount of the taker asset received in this fill, raw units. */
  takerAmount: bigint;
}

/** An order's state as reported by 1inch (`GET /orders/:hash`). */
export interface FusionStatus {
  /** 1inch status, e.g. "pending", "filled", "partially-filled", "expired". */
  status: string;
  makerAsset: string;
  takerAsset: string;
  fills: FusionFill[];
}

/** The 1inch Fusion API, scoped to the signer's wallet. */
export interface Fusion {
  /** Price a swap of `amount` of `from` into `to`. Never signs. */
  quote(from: string, to: string, amount: bigint): Promise<QuoteSummary>;
  /** Build (but do not sign) an order for the same swap. */
  build(from: string, to: string, amount: bigint): Promise<BuiltOrder>;
  /** Look up an order by hash. */
  status(hash: string): Promise<FusionStatus>;
}
