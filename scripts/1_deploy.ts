import { ethers } from "hardhat";
import CollectionConfig from "../config/CollectionConfig";
import { NftContractType } from "../lib/NftContractProvider";

async function main() {

  console.log("Deploying contract..");

  // We get the contract to deploy
  const Contract = await ethers.getContractFactory(CollectionConfig.contractName);
  const contractArguments = [
    CollectionConfig.platformAddressForLocalHost,
    CollectionConfig.domainEip712,
    CollectionConfig.versionDomain
  ]
  const contract = await Contract.deploy(...contractArguments) as unknown as NftContractType;

  await contract.deployed();

  console.log("Greeter deployed to:", contract.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});