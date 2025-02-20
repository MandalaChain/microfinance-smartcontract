import CollectionConfig from "./CollectionConfig";

const ContractArguments = [
    CollectionConfig.platformAddress,
    CollectionConfig.domainEip712,
    CollectionConfig.versionDomain
] as const;

export default ContractArguments;