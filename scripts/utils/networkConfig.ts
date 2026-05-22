import CollectionConfig from "../../config/CollectionConfig";

export interface NetworkConfig {
  chainId: number;
  name: string;
  shouldVerify: boolean;
  explorerBaseUrl?: string;
}

const NETWORK_CONFIG: Record<number, NetworkConfig> = {
  1337: {
    chainId: 1337,
    name: "localhost",
    shouldVerify: false,
  },
  31337: {
    chainId: 31337,
    name: "hardhat",
    shouldVerify: false,
  },
  20011: {
    chainId: 20011,
    name: "mandalaTestnet",
    shouldVerify: true,
    explorerBaseUrl: "https://explorer.testnet.mandalachain.io",
  },
  20010: {
    chainId: 20010,
    name: "mandalaMainnet",
    shouldVerify: true,
    explorerBaseUrl: "https://explorer.mandalachain.io",
  },
};

export function getNetworkConfig(chainId: number): NetworkConfig | null {
  return NETWORK_CONFIG[chainId] ?? null;
}

export function isLocalNetwork(chainId: number): boolean {
  return chainId === 1337 || chainId === 31337;
}

export function getPlatformAddress(chainId: number): string {
  return isLocalNetwork(chainId)
    ? CollectionConfig.platformAddressForLocalHost
    : CollectionConfig.platformAddress;
}

export function shouldVerifyContracts(chainId: number): boolean {
  const networkConfig = getNetworkConfig(chainId);
  return networkConfig?.shouldVerify ?? !isLocalNetwork(chainId);
}

export function getExplorerAddressUrl(
  chainId: number,
  address: string
): string | null {
  const networkConfig = getNetworkConfig(chainId);
  if (!networkConfig?.explorerBaseUrl) {
    return null;
  }

  return `${networkConfig.explorerBaseUrl}/address/${address}`;
}

export function getExplorerTransactionUrl(
  chainId: number,
  transactionHash: string
): string | null {
  const networkConfig = getNetworkConfig(chainId);
  if (!networkConfig?.explorerBaseUrl) {
    return null;
  }

  return `${networkConfig.explorerBaseUrl}/tx/${transactionHash}`;
}
