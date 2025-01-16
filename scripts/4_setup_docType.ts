// import { MerkleTree } from "merkletreejs";
// import keccak256 from "keccak256";
import { ethers } from "hardhat";
import NftContractProvider from "../lib/NftContractProvider";

async function main() {
    const [owner] = await ethers.getSigners();

    // attach to deploy contract
    const contract = await NftContractProvider.getContract();
  
    console.log("Setup address for development for address");
    await contract.connect(owner).setApproveClient("0x618D64266bFE4Ec30c05D26cc906480E21ccbFba", true);
    console.log("Done");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});