import { ethers, network } from "hardhat";
import { DataSharing as ContractType } from "../typechain-types";
import CollectionConfig from "../config/CollectionConfig";
import {
  getConfiguredContractAddress,
  getContractConfigKey,
} from "./CollectionConfigResolver";

export default class DataSharingContractProvider {
  public static getConfigKeyForChainId = (chainId: number) =>
    getContractConfigKey(chainId);

  public static getConfiguredAddress(chainId: number): string | null {
    return getConfiguredContractAddress(chainId);
  }

  public static async getContract(): Promise<ContractType> {
    const chainId = Number(network.config.chainId);
    const contractAddress = DataSharingContractProvider.getConfiguredAddress(
      chainId
    );

    if (contractAddress === null) {
      throw new Error(
        "Please add the deployed contract address to CollectionConfig before running this command."
      );
    }

    if ((await ethers.provider.getCode(contractAddress)) === "0x") {
      throw new Error(
        `Can't find a contract deployed to the target address: ${contractAddress}`
      );
    }

    const [owner] = await ethers.getSigners();

    return (await ethers.getContractAt(
      CollectionConfig.contractName,
      contractAddress,
      owner
    )) as unknown as ContractType;
  }
}

export type DataSharingContractType = ContractType;
export type NftContractType = ContractType;
