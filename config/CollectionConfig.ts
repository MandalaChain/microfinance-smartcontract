import CollectionConfigInterface from "../lib/CollectionConfigInterface";
import * as Networks from "../lib/Networks";

const CollectionConfig: CollectionConfigInterface = {
  local: Networks.hardhatLocal,
  testnet: Networks.mandalaTestnet,
  mainnet: Networks.mandalaMainnet,
  contractName: "DataSharing",
  local_address: "0x5FbDB2315678afecb367f032d93F642f64180aa3",
  mandalaMainnet_address: null,
  mandalaTestnet_address: "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd",
};

export default CollectionConfig;
