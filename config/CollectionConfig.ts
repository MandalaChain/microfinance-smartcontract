import CollectionConfigInterface from "../lib/CollectionConfigInterface";
import * as Networks from "../lib/Networks";
//import * as Marketpalce from "../lib/Marketplaces";

const CollectionConfig: CollectionConfigInterface = {
    testnet: Networks.niskala,
    mainnet: Networks.arbitrumOne,
    contractName: "DataSharing",
    platformAddress: "0x4c406d5fF749D73d0034be044b1C8DD57cF1134c", // account test
    domainEip712: "DataSharing",
    versionDomain: "1",
    contractAddress: "0x922872cA2B2FC36cE54EF998Ce1532D774A6511E",
    //marketplaceIdentifier: "market-place-identifier",
    //marketplaceConfig: Marketpalce.openSea
};

export default CollectionConfig;