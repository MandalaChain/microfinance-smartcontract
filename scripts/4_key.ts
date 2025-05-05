import { ethers } from "ethers";

async function main() {
  // 1. Your mnemonic (example only—do NOT use in production!)
  const mnemonic = "skin chicken ozone renew over snake whale video pepper furnace glory vote text fury doll";

  // 2. Create a wallet from the mnemonic
  const walletFromMnemonic = ethers.Wallet.fromMnemonic(mnemonic);

  // 3. Extract the private key
  const privateKey = walletFromMnemonic.privateKey;
  console.log("Private Key:", privateKey);
  console.log("publicKey:", walletFromMnemonic.getAddress());

  // 4. Derive the public key
  const signingKey = new ethers.utils.SigningKey(privateKey);
  const publicKey = signingKey.publicKey;
  console.log("Public Key:", publicKey);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
