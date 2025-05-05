import NftContractProvider from "../lib/NftContractProvider";
import { ethers } from "hardhat";

function hash32(identifier: string): string {
  return ethers.utils.keccak256(
    ethers.utils.defaultAbiCoder.encode(["string"], [identifier])
  );
}

async function main() {
  // attach to deploy contract
  const contract = await NftContractProvider.getContract();

  console.log("Add creditor");
  await contract.functions[
    "addCreditor(address,bytes32,string,string,string,string,string)"
  ](
    "0xb10436d45264bd7c929b55b2f04bea53081abefb",
    hash32("12345678"),
    "institutionCode",
    "institutionName",
    "approvalDate",
    "signerName",
    "signerPosition"
  );
  console.log("Done.");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
