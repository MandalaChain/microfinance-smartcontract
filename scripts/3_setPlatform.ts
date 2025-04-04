import NftContractProvider from "../lib/NftContractProvider";

async function main() {
    // attach to deploy contract
    const contract = await NftContractProvider.getContract();

    console.log("Set new platform");
    await contract.setPlatform("0xA6cbA3CF2d28EfEe1A9F7863a13E70C7e0aaEB29");
    console.log("Done");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});