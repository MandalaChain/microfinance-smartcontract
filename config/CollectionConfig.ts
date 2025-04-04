import CollectionConfigInterface from "../lib/CollectionConfigInterface";
import * as Networks from "../lib/Networks";
//import * as Marketpalce from "../lib/Marketplaces";

const CollectionConfig: CollectionConfigInterface = {
    testnet: Networks.niskala,
    mainnet: Networks.arbitrumOne,
    contractName: "DataSharing",
    platformAddress: "0xA6cbA3CF2d28EfEe1A9F7863a13E70C7e0aaEB29", // account test
    domainEip712: "DataSharing",
    versionDomain: "1",
    contractAddress: "0x922872cA2B2FC36cE54EF998Ce1532D774A6511E",
    //marketplaceIdentifier: "market-place-identifier",
    //marketplaceConfig: Marketpalce.openSea
};

export default CollectionConfig;