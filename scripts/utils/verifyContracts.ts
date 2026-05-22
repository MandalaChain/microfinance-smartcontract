import hre from "hardhat";
// @ts-ignore
import { ethers } from "hardhat";

export function delay(ms: number) {
  return new Promise((r) => setTimeout(r, ms));
}

/**
 * Programmatic verify helper for hardhat-etherscan.
 * @param address deployed address
 * @param constructorArguments flat array of constructor args
 * @param fullyQualified optional "contracts/Path.sol:ContractName"
 */
export async function verifyContract(
  address: string,
  constructorArguments: any[] = [],
  fullyQualified?: string
) {
  if (!address || address === ethers.ZeroAddress) {
    throw new Error("Skip verify: zero address");
  }

  const code = await ethers.provider.getCode(address);
  if (!code || code === "0x") {
    throw new Error(`Skip verify: no bytecode at ${address}`);
  }

  if (constructorArguments.some((x) => x === null || x === undefined)) {
    throw new Error(
      `Invalid constructorArguments contains null/undefined: ${JSON.stringify(
        constructorArguments
      )}`
    );
  }

  console.log(
    `Verifying ${address} with args: ${JSON.stringify(constructorArguments)}`
  );

  await delay(5_000);

  const params: any = {
    address,
    constructorArguments,
  };
  if (fullyQualified) params.contract = fullyQualified;

  let attempts = 2;
  while (attempts >= 0) {
    try {
      await hre.run("verify:verify", params);
      await delay(6_000);
      console.log("✓ Verify OK");
      return;
    } catch (e: any) {
      const msg = String(e?.message ?? e);
      if (/already verified/i.test(msg) || /source code already verified/i.test(msg)) {
        console.log("✓ Already verified on explorer");
        return;
      }
      if (attempts === 0) {
        console.warn("✖ Verify failed after retries.");
        throw new Error(msg);
      }
      console.warn(`[Verify] retrying... attempts left: ${attempts}`);
      await delay(4_000);
      attempts--;
    }
  }

  throw new Error("Verification failed after retries");
}
