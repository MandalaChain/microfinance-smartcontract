import { BaseContract, Signer } from "ethers";
import { ethers } from "hardhat";
import { explorerAddress, updateConfig, waitForTransaction } from "./helpers";
import { shouldVerifyContracts } from "./networkConfig";
import { verifyContract } from "./verifyContracts";

export interface DeployContractOptions {
  verify?: boolean;
  logArgs?: boolean;
  customDescription?: string;
  contractPath?: string;
}

export class ContractDeployer {
  constructor(
    private readonly networkName: string,
    private readonly chainId: number,
    private readonly signer: Signer
  ) {}

  async deployContract<TContract extends BaseContract>(
    contractName: string,
    args: readonly unknown[],
    configKey: string,
    options: DeployContractOptions = {}
  ): Promise<TContract> {
    const {
      verify = true,
      logArgs = true,
      customDescription,
      contractPath,
    } = options;

    console.log("================================================");
    console.log(
      `🚀 Deploying ${customDescription ?? contractName} on ${this.networkName}`
    );

    if (logArgs && args.length > 0) {
      console.log("     Using arguments:");
      args.forEach((arg, index) => {
        console.log(`       - Arg ${index}: ${String(arg)}`);
      });
    }
    console.log("================================================");

    const contract = await this.deployWithRetry<TContract>(contractName, args);
    const address = await contract.getAddress();

    console.log(`✅ ${customDescription ?? contractName} deployed: ${address}`);
    console.log("Link:", this.getExplorerLink(address));

    if (verify && shouldVerifyContracts(this.chainId)) {
      await this.verify(address, args, contractName, contractPath);
    }

    await this.updateConfig(configKey, address);

    console.log("✅ Done\n");

    return contract;
  }

  private async deployWithRetry<TContract extends BaseContract>(
    contractName: string,
    args: readonly unknown[],
    maxAttempts: number = 3
  ): Promise<TContract> {
    const contractFactory = await ethers.getContractFactory(
      contractName,
      this.signer
    );
    let lastError: unknown;

    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        const contract = (await contractFactory.deploy(...args)) as TContract;
        const deploymentTx = contract.deploymentTransaction();

        if (!deploymentTx) {
          throw new Error(`Missing deployment transaction for ${contractName}`);
        }

        const originalTxHash = deploymentTx.hash;

        const receipt = await waitForTransaction(deploymentTx, {
          label: `deploy ${contractName}`,
          chainId: this.chainId,
        });

        await contract.waitForDeployment();

        const address = await contract.getAddress();
        const minedTxHash = receipt?.hash ?? originalTxHash;
        const replacedTx =
          originalTxHash.toLowerCase() !== minedTxHash.toLowerCase();

        const code = await ethers.provider.getCode(address);
        if (code && code !== "0x") {
          return contract;
        }

        const reason =
          `Deployment tx confirmed but no bytecode at ${address}. ` +
          "This usually means another transaction replaced the deployment nonce.";

        if (replacedTx && attempt < maxAttempts) {
          console.log(
            `  ⚠️  ${reason} Retrying deployment (${attempt + 1}/${maxAttempts})...`
          );
          continue;
        }

        throw new Error(reason);
      } catch (error: any) {
        lastError = error;
        const message = error?.message || String(error);
        const isRecoverableNonceIssue =
          error?.code === "TRANSACTION_REPLACED" ||
          /nonce|replacement/i.test(message);

        if (isRecoverableNonceIssue && attempt < maxAttempts) {
          console.log(
            `  ⚠️  Deployment attempt ${attempt}/${maxAttempts} failed due to nonce replacement. Retrying...`
          );
          continue;
        }

        throw error;
      }
    }

    throw lastError ?? new Error(`Failed to deploy ${contractName}`);
  }

  private getExplorerLink(address: string): string {
    return explorerAddress(this.chainId, address);
  }

  private async verify(
    address: string,
    args: readonly unknown[],
    contractName: string,
    contractPath?: string
  ): Promise<void> {
    console.log(`Verifying ${contractName}...`);
    try {
      await verifyContract(address, [...args], contractPath);
      console.log("Contract verified successfully");
    } catch (error) {
      console.log(`⚠️  Verification failed for ${contractName}:`, error);
    }
  }

  private async updateConfig(key: string, address: string): Promise<void> {
    console.log("Update address on config...");
    await updateConfig(key, address);
  }
}
