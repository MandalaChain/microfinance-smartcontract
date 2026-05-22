import CollectionConfig from "../../config/CollectionConfig";
import {
  DATA_SHARING_CONTRACT_PATH,
  getDeploymentArgs,
} from "./deploymentConfig";

export interface VerifyStep {
  name: string;
  configKey: string;
  contractPath: string;
  customDescription?: string;
}

export const VERIFY_STEPS: VerifyStep[] = [
  {
    name: CollectionConfig.contractName,
    configKey: "contractAddress",
    contractPath: DATA_SHARING_CONTRACT_PATH,
    customDescription: "Microfinance data-sharing contract",
  },
];

export function getContractAddress(
  configKey: string,
  _chainId: number
): string | null {
  if (configKey !== "contractAddress") {
    throw new Error(`Unknown contract config key: ${configKey}`);
  }

  return CollectionConfig.contractAddress;
}

export function getConstructorArgs(
  chainId: number,
  configKey: string = "contractAddress"
): readonly [string, string, string] {
  if (configKey !== "contractAddress") {
    throw new Error(`Unknown contract config key: ${configKey}`);
  }

  return getDeploymentArgs(chainId);
}

export function getVerificationInfo(configKey: string, chainId: number) {
  const step = VERIFY_STEPS.find((candidate) => candidate.configKey === configKey);
  if (!step) {
    throw new Error(`Unknown contract config key: ${configKey}`);
  }

  return {
    name: step.name,
    address: getContractAddress(configKey, chainId),
    args: getConstructorArgs(chainId, configKey),
    contractPath: step.contractPath,
    description: step.customDescription,
  };
}

export function getAllVerificationInfo(chainId: number) {
  return VERIFY_STEPS.map((step) => ({
    name: step.name,
    configKey: step.configKey,
    address: getContractAddress(step.configKey, chainId),
    args: getConstructorArgs(chainId, step.configKey),
    contractPath: step.contractPath,
    description: step.customDescription,
  }));
}
