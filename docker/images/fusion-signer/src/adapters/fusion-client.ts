/**
 * Production `Fusion`: the 1inch Fusion API via @1inch/fusion-sdk.
 *
 * Quotes, builds, signs (EIP-712, with the wallet key) and submits Fusion
 * orders for the signer's wallet, and looks up order status. The SDK
 * objects are reduced to the plain shapes in ports.ts; in particular
 * `build` reports the fields the guard needs from the exact order that
 * `submit` later signs.
 */
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

/**
 * Created in main.ts with the signer's wallet, and in quote-check.ts with a
 * throwaway wallet.
 */
export class FusionClient implements Fusion {
  private readonly sdk: FusionSDK;

  /**
   * `privateKey` signs orders inside the SDK's connector; `provider` serves
   * the SDK's read calls; `authKey` is the 1inch Dev Portal API key.
   */
  constructor(
    private readonly walletAddress: string,
    privateKey: string,
    provider: JsonRpcProvider,
    authKey: string,
  ) {
    // The minimal provider shape the SDK expects; only eth.call is used.
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

  /** SDK request parameters for swapping `amount` of `from` into `to`. */
  private params(from: string, to: string, amount: bigint) {
    return {
      fromTokenAddress: from,
      toTokenAddress: to,
      amount: amount.toString(),
      walletAddress: this.walletAddress,
    };
  }

  /**
   * Quote the swap and return the recommended preset's auction amounts:
   * start (best case) and end (worst case).
   */
  async quote(from: string, to: string, amount: bigint) {
    const q = await this.sdk.getQuote(this.params(from, to, amount));
    const preset = q.presets[q.recommendedPreset];
    if (!preset) throw new Error("1inch quote has no recommended preset");
    return {
      startAmount: preset.auctionStartAmount,
      endAmount: preset.auctionEndAmount,
    } satisfies QuoteSummary;
  }

  /**
   * Build an unsigned order. The summary is read from the same order object
   * that `submit` signs, so the guard checks exactly what gets signed.
   * `receiver` is the SDK's `realReceiver` (where funds really go), not the
   * order-struct receiver, which can be a settlement contract.
   */
  async build(from: string, to: string, amount: bigint): Promise<BuiltOrder> {
    const prepared = await this.sdk.createOrder(this.params(from, to, amount));
    const o = prepared.order;
    return {
      summary: {
        hash: prepared.hash,
        maker: o.maker.toString(),
        receiver: o.realReceiver.toString(),
        settlement: o.settlementExtensionContract.toString(),
        makerAsset: o.makerAsset.toString(),
        takerAsset: o.takerAsset.toString(),
        makingAmount: o.makingAmount,
        takingAmount: o.takingAmount,
      },
      submit: async () => {
        const info = await this.sdk.submitOrder(o, prepared.quoteId);
        // Defense in depth only: this compares the hash the SDK computed
        // locally for the order it built, not an independent source.
        if (info.orderHash.toLowerCase() !== prepared.hash.toLowerCase()) {
          throw new Error(
            "SDK order hash differs from the locally computed hash",
          );
        }
        return info.orderHash;
      },
    };
  }

  /** Order status and fills, with the SDK's string amounts as bigints. */
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
