import CollectionConfigInterface from "../lib/CollectionConfigInterface";
import * as Networks from "../lib/Networks";

const CollectionConfig: CollectionConfigInterface = {
  local: Networks.hardhatLocal,
  testnet: Networks.mandalaTestnet,
  mainnet: Networks.mandalaMainnet,
  contractName: "DataSharing",
  local_address: "0x1234567890abcdef1234567890abcdef12345678",
  mandalaMainnet_address: null,
  mandalaTestnet_address: "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd",
};

export default CollectionConfig;
