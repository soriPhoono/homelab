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
  /** The 1inch settlement extension contract the order is bound to. */
  settlement: string;
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
