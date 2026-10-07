import { Contract, JsonRpcProvider, Wallet } from "ethers";
import type { Chain } from "../ports.js";
import { CHAIN_ID } from "../tokens.js";

const ERC20 = [
  "function decimals() view returns (uint8)",
  "function balanceOf(address) view returns (uint256)",
  "function allowance(address,address) view returns (uint256)",
  "function approve(address,uint256) returns (bool)",
  "function transfer(address,uint256) returns (bool)",
];

/** Base also charges an L1 data fee that gas estimates leave out. */
const L1_FEE_MARGIN = 10n ** 13n; // 0.00001 ETH

export class EthersChain implements Chain {
  readonly address: string;
  private readonly wallet: Wallet;

  constructor(
    readonly provider: JsonRpcProvider,
    privateKey: string,
  ) {
    this.wallet = new Wallet(privateKey, provider);
    this.address = this.wallet.address;
  }

  static connect(rpcUrl: string, privateKey: string): EthersChain {
    const provider = new JsonRpcProvider(rpcUrl, CHAIN_ID, {
      staticNetwork: true,
    });
    return new EthersChain(provider, privateKey);
  }

  private fn(token: string, name: string) {
    return new Contract(token, ERC20, this.wallet).getFunction(name);
  }

  async chainId(): Promise<number> {
    return Number(await this.provider.send("eth_chainId", []));
  }

  async decimals(token: string): Promise<number> {
    return Number(await this.fn(token, "decimals")());
  }

  async balance(token: string): Promise<bigint> {
    return (await this.fn(token, "balanceOf")(this.address)) as bigint;
  }

  ethBalance(): Promise<bigint> {
    return this.provider.getBalance(this.address);
  }

  async allowance(token: string, spender: string): Promise<bigint> {
    const read = this.fn(token, "allowance");
    return (await read(this.address, spender)) as bigint;
  }

  async approve(token: string, spender: string, amount: bigint) {
    const tx = await this.fn(token, "approve")(spender, amount);
    return tx.hash as string;
  }

  async transfer(token: string, to: string, amount: bigint) {
    const tx = await this.fn(token, "transfer")(to, amount);
    return tx.hash as string;
  }

  async sendEth(to: string, amount: bigint): Promise<string> {
    const tx = await this.wallet.sendTransaction({ to, value: amount });
    return tx.hash;
  }

  async gasCost(kind: "erc20" | "eth"): Promise<bigint> {
    const fee = await this.provider.getFeeData();
    const price = fee.maxFeePerGas ?? fee.gasPrice ?? 0n;
    const limit = kind === "eth" ? 21_000n : 65_000n;
    return (limit * price * 12n) / 10n + L1_FEE_MARGIN;
  }
}
