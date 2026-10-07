/**
 * Production `Chain`: the signer's wallet on Base, via ethers v6.
 *
 * Holds the private key in an ethers `Wallet` (in memory only) and uses it
 * to read balances and allowances and to send approve, transfer and native
 * ETH transactions. Thin by design: every rule lives in the service and
 * guard, which are tested against a fake of this interface.
 */
import { Contract, JsonRpcProvider, Wallet } from "ethers";
import type { Chain } from "../ports.js";
import { CHAIN_ID } from "../tokens.js";

/** The only ERC-20 functions the signer ever calls. */
const ERC20 = [
  "function decimals() view returns (uint8)",
  "function balanceOf(address) view returns (uint256)",
  "function allowance(address,address) view returns (uint256)",
  "function approve(address,uint256) returns (bool)",
  "function transfer(address,uint256) returns (bool)",
];

/**
 * Base's GasPriceOracle predeploy. It reports the L1 data fee a transaction
 * pays on top of L2 gas.
 */
const GAS_PRICE_ORACLE = "0x420000000000000000000000000000000000000F";

/** The one oracle function used by `gasCost`. */
const ORACLE_ABI = [
  "function getL1FeeUpperBound(uint256) view returns (uint256)",
];

/**
 * Fallback when the oracle is unreadable. Base also charges an L1 data fee
 * that gas estimates leave out.
 */
const L1_FEE_MARGIN = 10n ** 13n; // 0.00001 ETH

/** One instance per process, created in main.ts via `connect`. */
export class EthersChain implements Chain {
  readonly address: string;
  /** Signs transactions; never exposed outside this class. */
  private readonly wallet: Wallet;

  /**
   * `provider` is public so FusionClient can reuse the same RPC connection
   * for its read calls.
   */
  constructor(
    readonly provider: JsonRpcProvider,
    privateKey: string,
  ) {
    this.wallet = new Wallet(privateKey, provider);
    this.address = this.wallet.address;
  }

  /**
   * Connect to `rpcUrl` as Base. `staticNetwork` skips ethers' own network
   * probing; the real chain id is still checked by startupChecks via
   * `chainId()`.
   */
  static connect(rpcUrl: string, privateKey: string): EthersChain {
    const provider = new JsonRpcProvider(rpcUrl, CHAIN_ID, {
      staticNetwork: true,
    });
    return new EthersChain(provider, privateKey);
  }

  /** An ERC-20 function on `token`, bound to the wallet for signing. */
  private fn(token: string, name: string) {
    return new Contract(token, ERC20, this.wallet).getFunction(name);
  }

  /** Chain id straight from the RPC (eth_chainId). */
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

  /** Returns as soon as the transaction is broadcast (not mined). */
  async approve(token: string, spender: string, amount: bigint) {
    const tx = await this.fn(token, "approve")(spender, amount);
    return tx.hash as string;
  }

  /** Returns as soon as the transaction is broadcast (not mined). */
  async transfer(token: string, to: string, amount: bigint) {
    const tx = await this.fn(token, "transfer")(to, amount);
    return tx.hash as string;
  }

  /** Returns as soon as the transaction is broadcast (not mined). */
  async sendEth(to: string, amount: bigint): Promise<string> {
    const tx = await this.wallet.sendTransaction({ to, value: amount });
    return tx.hash;
  }

  /** Upper bound of the L1 data fee from Base's GasPriceOracle. */
  protected async l1FeeUpperBound(txSize: bigint): Promise<bigint> {
    const oracle = new Contract(GAS_PRICE_ORACLE, ORACLE_ABI, this.provider);
    return (await oracle.getFunction("getL1FeeUpperBound")(txSize)) as bigint;
  }

  /**
   * Wei one transfer will cost, with margin: L2 gas (21000 for ETH, 65000
   * for an ERC-20, times the max fee, plus 20%) plus the L1 data fee upper
   * bound (plus 50%), or the fixed fallback if the oracle call fails. Used
   * by withdrawals to keep enough ETH for gas.
   */
  async gasCost(kind: "erc20" | "eth"): Promise<bigint> {
    const fee = await this.provider.getFeeData();
    const price = fee.maxFeePerGas ?? fee.gasPrice ?? 0n;
    const limit = kind === "eth" ? 21_000n : 65_000n;
    const l2 = (limit * price * 12n) / 10n;
    let l1: bigint;
    try {
      const upper = await this.l1FeeUpperBound(kind === "eth" ? 120n : 180n);
      l1 = (upper * 3n) / 2n;
    } catch {
      l1 = L1_FEE_MARGIN;
    }
    return l2 + l1;
  }
}
