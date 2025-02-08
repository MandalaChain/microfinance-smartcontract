import CollectionConfigInterface from "../lib/CollectionConfigInterface";
import * as Networks from "../lib/Networks";
//import * as Marketpalce from "../lib/Marketplaces";

const CollectionConfig: CollectionConfigInterface = {
    testnet: Networks.niskala,
    mainnet: Networks.arbitrumOne,
    contractName: "DataSharing",
    platformAddress: "0x618D64266bFE4Ec30c05D26cc906480E21ccbFba", // account test
    domainEip712: "DataSharing",
    versionDomain: "1",
    contractAddress: "0x1E8E93ff202e046D46E2d7fe9b0a8471F07e945D",
    //marketplaceIdentifier: "market-place-identifier",
    //marketplaceConfig: Marketpalce.openSea
};

export default CollectionConfig;