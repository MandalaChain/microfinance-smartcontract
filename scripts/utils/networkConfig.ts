import CollectionConfig from "../../config/CollectionConfig";
import {
  getConfiguredContractAddress as resolveConfiguredContractAddress,
  getContractConfigKey as resolveContractConfigKey,
} from "../../lib/CollectionConfigResolver";
import { ContractAddressConfigKey } from "../../lib/CollectionConfigInterface";

export interface NetworkConfig {
  chainId: number;
  name: string;
  shouldVerify: boolean;
  explorerBaseUrl?: string;
  configAddressKey: ContractAddressConfigKey;
}

const NETWORK_CONFIG: Record<number, NetworkConfig> = {
  1337: {
    chainId: 1337,
    name: "localhost",
    shouldVerify: false,
    configAddressKey: "local_address",
  },
  31337: {
    chainId: 31337,
    name: "hardhat",
    shouldVerify: false,
    configAddressKey: "local_address",
  },
  20011: {
    chainId: 20011,
    name: "mandalaTestnet",
    shouldVerify: true,
    explorerBaseUrl: "https://explorer.testnet.mandalachain.io",
    configAddressKey: "mandalaTestnet_address",
  },
  20010: {
    chainId: 20010,
    name: "mandalaMainnet",
    shouldVerify: true,
    explorerBaseUrl: "https://explorer.mandalachain.io",
    configAddressKey: "mandalaMainnet_address",
  },
};

export function getNetworkConfig(chainId: number): NetworkConfig | null {
  return NETWORK_CONFIG[chainId] ?? null;
}

export function isLocalNetwork(chainId: number): boolean {
  return chainId === CollectionConfig.local.chainId || chainId === 31337;
}

export function getContractConfigKey(chainId: number): ContractAddressConfigKey {
  return resolveContractConfigKey(chainId);
}

export function getConfiguredContractAddress(chainId: number): string | null {
  return resolveConfiguredContractAddress(chainId);
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
