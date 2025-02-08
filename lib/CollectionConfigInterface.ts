import NetworkConfigInterface from "./NetworkConfigInterface";
//import MarketplaceConfigInterface from "./MarketplaceConfigInterface";

export default interface CollectionConfigInterface {
    testnet: NetworkConfigInterface;
    mainnet: NetworkConfigInterface;
    contractName: string;
    platformAddress: string;
    domainEip712: string;
    versionDomain: string;
    contractAddress: string|null;
    //marketplaceIdentifier: string;
    //marketplaceConfig: MarketplaceConfigInterface;
};