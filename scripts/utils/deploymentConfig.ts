import CollectionConfig from "../../config/CollectionConfig";
import { getPlatformAddress } from "./networkConfig";

export interface DeploymentContext {
  chainId: number;
  [key: string]: unknown;
}

export interface DeploymentStep {
  name: string;
  contractName: string;
  configKey: string;
  contractPath: string;
  getArgs: (context: DeploymentContext) => readonly [string, string, string];
  customDescription?: string;
}

export const DATA_SHARING_CONTRACT_PATH = `contracts/${CollectionConfig.contractName}.sol:${CollectionConfig.contractName}`;

export function getDeploymentArgs(
  chainId: number
): readonly [string, string, string] {
  return [
    getPlatformAddress(chainId),
    CollectionConfig.domainEip712,
    CollectionConfig.versionDomain,
  ] as const;
}

export const DEPLOYMENT_STEPS: DeploymentStep[] = [
  {
    name: CollectionConfig.contractName,
    contractName: CollectionConfig.contractName,
    configKey: "contractAddress",
    contractPath: DATA_SHARING_CONTRACT_PATH,
    getArgs: (context) => getDeploymentArgs(context.chainId),
    customDescription: "Microfinance data-sharing contract",
  },
];
