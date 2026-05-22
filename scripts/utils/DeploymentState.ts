import fs from "fs";
import path from "path";

export interface DeploymentRecord {
  address: string;
  timestamp: number;
  blockNumber?: number;
  transactionHash?: string;
}

export interface NetworkDeployments {
  [contractName: string]: DeploymentRecord;
}

export interface DeploymentStateData {
  [chainId: number]: NetworkDeployments;
}

export class DeploymentState {
  private statePath: string;
  private deploymentsDir: string;

  constructor(statePath?: string) {
    this.deploymentsDir = path.resolve(__dirname, "../../deployments");
    this.statePath =
      statePath || path.join(this.deploymentsDir, "deployment-state.json");

    // Create deployments directory if it doesn't exist
    if (!fs.existsSync(this.deploymentsDir)) {
      fs.mkdirSync(this.deploymentsDir, { recursive: true });
    }
  }

  /**
   * Save deployment information for a contract
   */
  save(
    chainId: number,
    contractName: string,
    address: string,
    additionalInfo?: Partial<DeploymentRecord>
  ): void {
    const state = this.loadAll();

    if (!state[chainId]) {
      state[chainId] = {};
    }

    state[chainId][contractName] = {
      address,
      timestamp: Date.now(),
      ...additionalInfo,
    };

    this.writeState(state);
    console.log(
      `💾 Saved deployment state for ${contractName} on chain ${chainId}`
    );
  }

  /**
   * Save multiple contracts at once
   */
  saveMultiple(
    chainId: number,
    contracts: Record<string, string>
  ): void {
    const state = this.loadAll();

    if (!state[chainId]) {
      state[chainId] = {};
    }

    Object.entries(contracts).forEach(([name, address]) => {
      state[chainId][name] = {
        address,
        timestamp: Date.now(),
      };
    });

    this.writeState(state);
    console.log(`💾 Saved ${Object.keys(contracts).length} contracts to state`);
  }

  /**
   * Load deployment state for a specific network
   */
  load(chainId: number): NetworkDeployments {
    const state = this.loadAll();
    return state[chainId] || {};
  }

  /**
   * Load all deployment states
   */
  loadAll(): DeploymentStateData {
    if (!fs.existsSync(this.statePath)) {
      return {};
    }

    try {
      const content = fs.readFileSync(this.statePath, "utf8");
      return JSON.parse(content);
    } catch (error) {
      console.warn("⚠️  Failed to load deployment state:", error);
      return {};
    }
  }

  /**
   * Check if a contract has been deployed on a network
   */
  hasDeployment(chainId: number, contractName: string): boolean {
    const state = this.load(chainId);
    return !!state[contractName];
  }

  /**
   * Get deployment address for a contract
   */
  getAddress(chainId: number, contractName: string): string | null {
    const state = this.load(chainId);
    return state[contractName]?.address || null;
  }

  /**
   * Get all deployed contracts for a network
   */
  getDeployedContracts(chainId: number): string[] {
    const state = this.load(chainId);
    return Object.keys(state);
  }

  /**
   * Clear deployment state for a specific network
   */
  clear(chainId: number): void {
    const state = this.loadAll();
    delete state[chainId];
    this.writeState(state);
    console.log(`🗑️  Cleared deployment state for chain ${chainId}`);
  }

  /**
   * Clear all deployment states
   */
  clearAll(): void {
    this.writeState({});
    console.log("🗑️  Cleared all deployment states");
  }

  /**
   * Generate a deployment report
   */
  generateReport(chainId: number, networkName: string): string {
    const state = this.load(chainId);
    const contracts = Object.entries(state);

    if (contracts.length === 0) {
      return `No deployments found for ${networkName} (Chain ID: ${chainId})`;
    }

    let report = `# Deployment Report\n\n`;
    report += `**Network:** ${networkName}\n`;
    report += `**Chain ID:** ${chainId}\n`;
    report += `**Date:** ${new Date().toISOString()}\n\n`;
    report += `## Deployed Contracts\n\n`;
    report += `| Contract | Address | Deployed At |\n`;
    report += `|----------|---------|-------------|\n`;

    contracts.forEach(([name, info]) => {
      const date = new Date(info.timestamp).toLocaleString();
      report += `| ${name} | \`${info.address}\` | ${date} |\n`;
    });

    return report;
  }

  /**
   * Save deployment report to file
   */
  saveReport(chainId: number, networkName: string): void {
    const report = this.generateReport(chainId, networkName);
    const timestamp = new Date().toISOString().split("T")[0];
    const filename = `${networkName}-${chainId}-${timestamp}.md`;
    const reportPath = path.join(this.deploymentsDir, filename);

    fs.writeFileSync(reportPath, report);
    console.log(`📄 Deployment report saved to: ${reportPath}`);
  }

  private writeState(state: DeploymentStateData): void {
    fs.writeFileSync(this.statePath, JSON.stringify(state, null, 2), "utf8");
  }
}
