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

export class FusionClient implements Fusion {
  private readonly sdk: FusionSDK;

  constructor(
    private readonly walletAddress: string,
    privateKey: string,
    provider: JsonRpcProvider,
    authKey: string,
  ) {
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

  private params(from: string, to: string, amount: bigint) {
    return {
      fromTokenAddress: from,
      toTokenAddress: to,
      amount: amount.toString(),
      walletAddress: this.walletAddress,
    };
  }

  async quote(from: string, to: string, amount: bigint) {
    const q = await this.sdk.getQuote(this.params(from, to, amount));
    const preset = q.presets[q.recommendedPreset];
    if (!preset) throw new Error("1inch quote has no recommended preset");
    return {
      startAmount: preset.auctionStartAmount,
      endAmount: preset.auctionEndAmount,
    } satisfies QuoteSummary;
  }

  async build(from: string, to: string, amount: bigint): Promise<BuiltOrder> {
    const prepared = await this.sdk.createOrder(this.params(from, to, amount));
    const o = prepared.order;
    return {
      summary: {
        hash: prepared.hash,
        maker: o.maker.toString(),
        receiver: o.realReceiver.toString(),
        makerAsset: o.makerAsset.toString(),
        takerAsset: o.takerAsset.toString(),
        makingAmount: o.makingAmount,
        takingAmount: o.takingAmount,
      },
      submit: async () => {
        const info = await this.sdk.submitOrder(o, prepared.quoteId);
        if (info.orderHash.toLowerCase() !== prepared.hash.toLowerCase()) {
          throw new Error("1inch returned a different order hash");
        }
        return info.orderHash;
      },
    };
  }

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
