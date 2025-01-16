// import { MerkleTree } from "merkletreejs";
// import keccak256 from "keccak256";
import { ethers } from "hardhat";
import NftContractProvider from "../lib/NftContractProvider";

async function main() {
    const [owner] = await ethers.getSigners();

    // attach to deploy contract
    const contract = await NftContractProvider.getContract();

    console.log("Setup and verify document types...");
    await contract.connect(owner).approveDocType("LEVY");
    await contract.connect(owner).approveDocType("E-CERTIFICATE");
  
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});