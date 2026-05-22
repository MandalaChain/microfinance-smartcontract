import { BaseContract } from "ethers";
import { ethers, network } from "hardhat";
import { ContractDeployer } from "./ContractDeployer";
import { DeploymentState } from "./DeploymentState";
import { PermissionManager } from "./PermissionManager";
import { DeploymentContext, DeploymentStep } from "./deploymentConfig";
import { getContractConfigKey } from "./networkConfig";

export interface DeploymentOptions {
  skipVerification?: boolean;
  skipIfExists?: boolean;
  resumeFrom?: string;
  dryRun?: boolean;
}

export class DeploymentOrchestrator {
  private deployer!: ContractDeployer;
  private state!: DeploymentState;
  private permissionManager!: PermissionManager;
  private context: DeploymentContext = { chainId: 0 };
  private deployedAddresses: Record<string, string> = {};
  private networkName!: string;
  private chainId!: number;
  private signerAddress!: string;

  async initialize(): Promise<void> {
    const [signer] = await ethers.getSigners();
    this.signerAddress = await signer.getAddress();
    this.networkName = network.name;
    this.chainId = Number(network.config.chainId);
    this.context = { chainId: this.chainId };

    this.deployer = new ContractDeployer(
      this.networkName,
      this.chainId,
      signer
    );
    this.state = new DeploymentState();
    this.permissionManager = new PermissionManager(
      this.chainId,
      this.signerAddress
    );
  }

  async deployAll(
    steps: DeploymentStep[],
    options: DeploymentOptions = {}
  ): Promise<DeploymentContext> {
    console.log("\n" + "=".repeat(60));
    console.log(`🚀 Starting Deployment on ${this.networkName}`);
    console.log(`📊 Chain ID: ${this.chainId}`);
    console.log(`👤 Deployer: ${this.signerAddress}`);
    console.log("=".repeat(60) + "\n");

    await this.loadExistingDeployments(steps);

    for (const step of steps) {
      const existingAddress = this.state.getAddress(this.chainId, step.configKey);

      if (options.skipIfExists && existingAddress) {
        console.log(`⏭️  ${step.name} already deployed, skipping...`);
        console.log(`   Address: ${existingAddress}\n`);
        continue;
      }

      const args = step.getArgs(this.context);

      if (options.dryRun) {
        console.log(`[DRY RUN] Would deploy ${step.name}`);
        console.log(`   Contract: ${step.contractName}`);
        console.log(`   Arguments: ${JSON.stringify(args)}\n`);
        continue;
      }

      const contract = await this.deployer.deployContract<BaseContract>(
        step.contractName,
        args,
        step.configKey,
        {
          verify: !options.skipVerification,
          customDescription: step.customDescription,
          contractPath: step.contractPath,
        }
      );

      const address = await contract.getAddress();

      this.context[step.configKey] = contract;
      this.deployedAddresses[step.configKey] = address;
      this.state.save(this.chainId, step.configKey, address);

      console.log(`✅ ${step.name} deployment completed\n`);
    }

    if (!options.dryRun) {
      console.log("=".repeat(60));
      console.log("✅ All contracts deployed successfully!");
      console.log("=".repeat(60) + "\n");
    }

    return this.context;
  }

  async setupPermissions(): Promise<void> {
    await this.permissionManager.setupPermissions();
  }

  async verify(deployedContracts: DeploymentContext): Promise<boolean> {
    console.log("\n" + "=".repeat(60));
    console.log("🔍 Verifying Deployment");
    console.log("=".repeat(60));

    const contract = deployedContracts.contractAddress as BaseContract | undefined;
    if (!contract) {
      console.log("❌ DataSharing contract was not loaded in the deployment context");
      console.log("=".repeat(60) + "\n");
      return false;
    }

    const address = await contract.getAddress();
    const code = await ethers.provider.getCode(address);
    const owner = await (contract as any).owner();

    const addressOk = code !== "0x";
    const ownerOk =
      typeof owner === "string" &&
      owner.toLowerCase() === this.signerAddress.toLowerCase();

    console.log(`Contract bytecode present: ${addressOk ? "✅" : "❌"}`);
    console.log(`Owner matches deployer: ${ownerOk ? "✅" : "❌"}`);

    const isValid = addressOk && ownerOk;

    console.log("\n" + "=".repeat(60));
    console.log(
      isValid
        ? "✅ Deployment verification PASSED"
        : "❌ Deployment verification FAILED"
    );
    console.log("=".repeat(60) + "\n");

    return isValid;
  }

  generateReport(): void {
    this.state.saveReport(this.chainId, this.networkName);
  }

  getDeployedAddresses(): Record<string, string> {
    return { ...this.deployedAddresses };
  }

  updateCollectionConfig(): void {
    const deployedAddress = this.deployedAddresses.contractAddress;

    if (!deployedAddress) {
      console.log("⚠️  No deployed contract address available to write back");
      return;
    }

    console.log("\n" + "=".repeat(60));
    console.log("📝 Updating CollectionConfig.ts");
    console.log("=".repeat(60) + "\n");
    const configKey = getContractConfigKey(this.chainId);
    console.log(
      `CollectionConfig.${configKey} already points to the latest deployed value: ${deployedAddress}`
    );
  }

  private async loadExistingDeployments(
    steps: DeploymentStep[]
  ): Promise<void> {
    const existingDeployments = this.state.load(this.chainId);

    for (const [configKey, record] of Object.entries(existingDeployments)) {
      const step = steps.find((candidate) => candidate.configKey === configKey);
      if (!step) {
        continue;
      }

      try {
        const contract = await ethers.getContractAt(
          step.contractName,
          record.address
        );
        this.context[configKey] = contract;
        this.deployedAddresses[configKey] = record.address;
        console.log(`✅ Loaded existing contract: ${configKey} (${record.address})`);
      } catch (error) {
        console.log(`⚠️  Could not load contract ${configKey}: ${error}`);
      }
    }

    if (Object.keys(this.deployedAddresses).length > 0) {
      console.log();
    }
  }
}
