import NetworkConfigInterface from "./NetworkConfigInterface";

/*
 * Local Networks
*/
export const hardhatLocal: NetworkConfigInterface = {
    chainId: 1337,
    symbol: "eth (test)",
    blockExplorer: {
        name: "Block explorer (not available for local chains)",
        generatorContractUrl: (contractAddress: string) => "#",
        generateTransactionUrl: (transactionAddress: string) => `#`,
    },
}

/*
 * MANDALA
 */
export const mandalaTestnet: NetworkConfigInterface = {
  chainId: 20011,
  symbol: "KPGT",
  blockExplorer: {
    name: "Mandala Testnet",
    generatorContractUrl: (contractAddress: string) => `https://explorer.testnet.mandalachain.io/address/${contractAddress}`,
    generateTransactionUrl: (transactionAddress: string) => `https://explorer.testnet.mandalachain.io/tx/${transactionAddress}`,
  }
};

export const mandalaMainnet: NetworkConfigInterface = {
  chainId: 20010,
  symbol: "KPG",
  blockExplorer: {
    name: "Mandala Mainnet",
    generatorContractUrl: (contractAddress: string) => `https://explorer.mandalachain.io/address/${contractAddress}`,
    generateTransactionUrl: (transactionAddress: string) => `https://explorer.mandalachain.io/tx/${transactionAddress}`,
  }
};
