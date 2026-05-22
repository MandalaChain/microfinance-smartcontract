import path from "path";
import fs from "fs";
import {
  getExplorerAddressUrl,
  getExplorerTransactionUrl,
} from "./networkConfig";

export function explorer(chainId: number, txHash: string) {
  return getExplorerTransactionUrl(chainId, txHash) ?? txHash;
}

export function explorerAddress(chainId: number, address: string) {
  return getExplorerAddressUrl(chainId, address) ?? address;
}

/**
 * Wait for transaction confirmation and tolerate ethers v5 replacement errors
 * when the replacement transaction was actually mined successfully.
 */
export async function waitForTransaction(
  tx: {
    wait: (confirmations?: number) => Promise<any>;
    hash?: string;
    provider?: {
      getTransactionReceipt?: (hash: string) => Promise<any>;
    };
  },
  options: {
    confirmations?: number;
    label?: string;
    chainId?: number;
    timeoutMs?: number;
  } = {}
) {
  const waitWithOptionalTimeout = async () => {
    if (!options.timeoutMs || options.timeoutMs <= 0) {
      return tx.wait(options.confirmations);
    }

    return new Promise<any>((resolve, reject) => {
      const timer = setTimeout(() => {
        const context = options.label ? `${options.label}: ` : "";
        const timeoutError: any = new Error(
          `${context}timed out waiting for transaction confirmation after ${options.timeoutMs}ms`
        );
        timeoutError.code = "TX_WAIT_TIMEOUT";
        timeoutError.txHash = tx.hash;
        reject(timeoutError);
      }, options.timeoutMs);

      tx.wait(options.confirmations)
        .then((receipt) => {
          clearTimeout(timer);
          resolve(receipt);
        })
        .catch((error) => {
          clearTimeout(timer);
          reject(error);
        });
    });
  };

  try {
    return await waitWithOptionalTimeout();
  } catch (error: any) {
    if (error?.code === "TRANSACTION_REPLACED") {
      const replacementHash = error?.replacement?.hash;
      const replacementReceipt = error?.receipt;
      const replacementSucceeded = replacementReceipt?.status === 1;

      if (replacementHash && replacementSucceeded) {
        const context = options.label ? `${options.label}: ` : "";
        console.log(
          `  ⚠️  ${context}transaction replaced; using mined replacement ${replacementHash}`
        );
        if (options.chainId) {
          console.log(`     Tx: ${explorer(options.chainId, replacementHash)}`);
        }
        return replacementReceipt;
      }
    }

    if (error?.code === "TX_WAIT_TIMEOUT" && tx.hash) {
      const provider = tx.provider;
      if (provider?.getTransactionReceipt) {
        const receipt = await provider.getTransactionReceipt(tx.hash);
        if (receipt) {
          const context = options.label ? `${options.label}: ` : "";
          console.log(
            `  ⚠️  ${context}wait timed out, but receipt found for ${tx.hash}; continuing`
          );
          return receipt;
        }
      }
    }

    throw error;
  }
}

export async function updateConfig(key: string, address: string) {
  const configPath = path.resolve(__dirname, "../../config/CollectionConfig.ts");
  if (fs.existsSync(configPath)) {
    let file = fs.readFileSync(configPath, "utf-8");
    const regex = new RegExp(`(${key}:\\s*)(["'][^"']*["']|null)`, "g");
    if (regex.test(file)) {
      file = file.replace(regex, `$1"${address}"`);
      fs.writeFileSync(configPath, file);
      console.log(`\n✅ Updated ${key} in CollectionConfig.ts: ${address}`);
    } else {
      console.log("⚠️  Config pattern not found for update!");
    }
  }
}
