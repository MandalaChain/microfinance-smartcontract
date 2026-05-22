import NetworkConfigInterface from "./NetworkConfigInterface";

export type ContractAddressConfigKey =
  | "local_address"
  | "mandalaMainnet_address"
  | "mandalaTestnet_address";

export default interface CollectionConfigInterface {
  local: NetworkConfigInterface;
  testnet: NetworkConfigInterface;
  mainnet: NetworkConfigInterface;
  contractName: string;
  local_address: string | null;
  mandalaMainnet_address: string | null;
  mandalaTestnet_address: string | null;
}
