import { getAddress, isAddress } from "ethers";
import CollectionConfig from "../config/CollectionConfig";
import { ContractAddressConfigKey } from "./CollectionConfigInterface";

const CONFIG_KEY_BY_CHAIN_ID: Record<number, ContractAddressConfigKey> = {
  1337: "local_address",
  31337: "local_address",
  20011: "mandalaTestnet_address",
  20010: "mandalaMainnet_address",
};

export function getContractConfigKey(chainId: number): ContractAddressConfigKey {
  const configKey = CONFIG_KEY_BY_CHAIN_ID[chainId];

  if (!configKey) {
    throw new Error(`Unsupported network chain ID: ${chainId}`);
  }

  return configKey;
}

export function getConfiguredContractAddress(chainId: number): string | null {
  const configKey = getContractConfigKey(chainId);
  const configuredAddress = CollectionConfig[configKey];

  if (configuredAddress === null) {
    return null;
  }

  if (!isAddress(configuredAddress)) {
    throw new Error(
      `Invalid address configured in CollectionConfig.${configKey}: ${configuredAddress}`
    );
  }

  return getAddress(configuredAddress);
}
