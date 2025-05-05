import CollectionConfigInterface from "../lib/CollectionConfigInterface";
import * as Networks from "../lib/Networks";
//import * as Marketpalce from "../lib/Marketplaces";

const CollectionConfig: CollectionConfigInterface = {
    testnet: Networks.niskala,
    mainnet: Networks.arbitrumOne,
    contractName: "DataSharing",
    platformAddress: "0xA6cbA3CF2d28EfEe1A9F7863a13E70C7e0aaEB29", // account test
    platformAddressForLocalHost: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
    domainEip712: "DataSharing",
    versionDomain: "1",
    contractAddress: "0x5740354Db8a705b9d6C35C487C137921776Fed7B",
    //marketplaceIdentifier: "market-place-identifier",
    //marketplaceConfig: Marketpalce.openSea
};

export default CollectionConfig;