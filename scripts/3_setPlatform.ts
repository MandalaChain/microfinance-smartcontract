import NftContractProvider from "../lib/NftContractProvider";

async function main() {
    // attach to deploy contract
    const contract = await NftContractProvider.getContract();

    console.log("Set new platform");
    await contract.setPlatform("0x7f4034bd07CDF9d4ad3CAC4B1C6Cb0e2A39b4713");
    console.log("Done");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});