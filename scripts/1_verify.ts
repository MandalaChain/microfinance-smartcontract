import { ethers, network } from "hardhat";
import { DeploymentState } from "./utils/DeploymentState";
import { delay, verifyContract } from "./utils/verifyContracts";
import {
  getAllVerificationInfo,
  getConstructorArgs,
} from "./utils/verifyConfig";
import { shouldVerifyContracts } from "./utils/networkConfig";

interface VerifyOptions {
  onlyContracts?: string[];
  skipContracts?: string[];
  dryRun: boolean;
  continueOnError: boolean;
  addressOverride?: string;
}

interface VerifyResult {
  name: string;
  configKey: string;
  address: string;
  status: "success" | "skipped" | "failed" | "already_verified";
  message?: string;
}

function parseBooleanEnv(
  value: string | undefined,
  defaultValue: boolean
): boolean {
  if (value === undefined) {
    return defaultValue;
  }

  const normalized = value.trim().toLowerCase();
  if (["1", "true", "yes", "on"].includes(normalized)) {
    return true;
  }
  if (["0", "false", "no", "off"].includes(normalized)) {
    return false;
  }

  return defaultValue;
}

function parseOptions(): VerifyOptions {
  return {
    onlyContracts: process.env.VERIFY_ONLY?.split(",")
      .map((value) => value.trim())
      .filter(Boolean),
    skipContracts: process.env.SKIP_CONTRACTS?.split(",")
      .map((value) => value.trim())
      .filter(Boolean),
    dryRun: parseBooleanEnv(process.env.DRY_RUN, false),
    continueOnError: parseBooleanEnv(process.env.CONTINUE_ON_ERROR, true),
    addressOverride: process.env.VERIFY_ADDRESS?.trim() || undefined,
  };
}

function shouldVerify(configKey: string, options: VerifyOptions): boolean {
  if (options.onlyContracts && options.onlyContracts.length > 0) {
    return options.onlyContracts.includes(configKey);
  }

  if (options.skipContracts?.includes(configKey)) {
    return false;
  }

  return true;
}

function resolveContractAddress(
  chainId: number,
  configKey: string,
  configuredAddress: string | null,
  addressOverride?: string
): string {
  if (addressOverride) {
    return addressOverride;
  }

  if (configuredAddress) {
    return configuredAddress;
  }

  const deploymentState = new DeploymentState();
  return deploymentState.getAddress(chainId, configKey) ?? "";
}

function printVerificationPlan(
  chainId: number,
  options: VerifyOptions,
  entries: Array<{
    name: string;
    configKey: string;
    address: string;
    args: readonly unknown[];
  }>
): void {
  console.log("\n" + "=".repeat(70));
  console.log("📋 Contract Verification Plan");
  console.log("=".repeat(70));
  console.log(`Network: ${network.name} (Chain ID: ${chainId})`);
  console.log("-".repeat(70));

  let verifyCount = 0;
  let skipCount = 0;

  entries.forEach((entry, index) => {
    const willVerify = shouldVerify(entry.configKey, options);
    if (willVerify) {
      verifyCount++;
    } else {
      skipCount++;
    }

    console.log(`\n${willVerify ? "✓" : "⊘"} [${index + 1}] ${entry.name}`);
    console.log(`   Key: ${entry.configKey}`);
    console.log(`   Address: ${entry.address || "NOT DEPLOYED"}`);
    console.log(`   Args: ${JSON.stringify(entry.args)}`);
    console.log(`   Status: ${willVerify ? "WILL VERIFY" : "SKIP"}`);
  });

  console.log("\n" + "-".repeat(70));
  console.log(`Total: ${verifyCount} to verify, ${skipCount} to skip`);
  console.log("=".repeat(70) + "\n");
}

async function verifySingleContract(
  name: string,
  configKey: string,
  address: string,
  args: readonly unknown[],
  contractPath: string,
  dryRun: boolean
): Promise<VerifyResult> {
  console.log(`\n🔍 Verifying: ${name}`);
  console.log(`   Address: ${address}`);
  console.log(`   Args: ${JSON.stringify(args)}`);

  if (!address || address === ethers.ZeroAddress) {
    console.log("   ⚠️  Skipped: No valid address");
    return {
      name,
      configKey,
      address: address || "N/A",
      status: "skipped",
      message: "No valid address",
    };
  }

  const code = await ethers.provider.getCode(address);
  if (!code || code === "0x") {
    console.log("   ⚠️  Skipped: No bytecode at address");
    return {
      name,
      configKey,
      address,
      status: "skipped",
      message: "No bytecode at address",
    };
  }

  if (dryRun) {
    console.log(
      `   📝 Dry run: Would verify with args ${JSON.stringify(args)}`
    );
    return {
      name,
      configKey,
      address,
      status: "skipped",
      message: "Dry run mode",
    };
  }

  try {
    await verifyContract(address, [...args], contractPath);
    console.log("   ✅ Verified successfully");
    return {
      name,
      configKey,
      address,
      status: "success",
    };
  } catch (error: any) {
    const message = String(error?.message ?? error);

    if (/already verified/i.test(message)) {
      console.log("   ✅ Already verified");
      return {
        name,
        configKey,
        address,
        status: "already_verified",
      };
    }

    console.log(`   ❌ Verification failed: ${message}`);
    return {
      name,
      configKey,
      address,
      status: "failed",
      message,
    };
  }
}

function printSummary(results: VerifyResult[]): void {
  console.log("\n" + "=".repeat(70));
  console.log("📊 Verification Summary");
  console.log("=".repeat(70));

  const successful = results.filter((result) => result.status === "success");
  const alreadyVerified = results.filter(
    (result) => result.status === "already_verified"
  );
  const skipped = results.filter((result) => result.status === "skipped");
  const failed = results.filter((result) => result.status === "failed");

  console.log(`\n✅ Verified: ${successful.length}`);
  successful.forEach((result) =>
    console.log(`   - ${result.name}: ${result.address}`)
  );

  console.log(`\n✅ Already Verified: ${alreadyVerified.length}`);
  alreadyVerified.forEach((result) =>
    console.log(`   - ${result.name}: ${result.address}`)
  );

  console.log(`\n⊘ Skipped: ${skipped.length}`);
  skipped.forEach((result) =>
    console.log(`   - ${result.name}: ${result.message}`)
  );

  if (failed.length > 0) {
    console.log(`\n❌ Failed: ${failed.length}`);
    failed.forEach((result) =>
      console.log(`   - ${result.name}: ${result.message}`)
    );
  }

  console.log("\n" + "=".repeat(70));
  console.log(
    failed.length === 0
      ? `🎉 Verification completed successfully (${successful.length + alreadyVerified.length}/${results.length})`
      : `⚠️  Verification completed with ${failed.length} failure(s)`
  );
  console.log("=".repeat(70) + "\n");
}

export async function main(): Promise<void> {
  const chainId = Number(network.config.chainId);

  if (!chainId) {
    throw new Error("Chain ID not found in network config");
  }

  if (!shouldVerifyContracts(chainId)) {
    console.log(
      `Verification is not supported for ${network.name} (chainId ${chainId}).`
    );
    return;
  }

  console.log("\n" + "=".repeat(70));
  console.log("🚀 DataSharing Contract Verification");
  console.log("=".repeat(70));
  console.log(`Network: ${network.name}`);
  console.log(`Chain ID: ${chainId}`);
  console.log(`Time: ${new Date().toISOString()}`);

  const options = parseOptions();
  if (options.dryRun) {
    console.log("\n📝 DRY RUN MODE - No actual verification will be performed");
  }

  const entries = getAllVerificationInfo(chainId).map((entry) => ({
    ...entry,
    address: resolveContractAddress(
      chainId,
      entry.configKey,
      entry.address,
      options.addressOverride
    ),
    args: getConstructorArgs(chainId, entry.configKey),
  }));

  printVerificationPlan(chainId, options, entries);

  const results: VerifyResult[] = [];

  for (const entry of entries) {
    if (!shouldVerify(entry.configKey, options)) {
      results.push({
        name: entry.name,
        configKey: entry.configKey,
        address: entry.address || "N/A",
        status: "skipped",
        message: "Excluded by options",
      });
      continue;
    }

    const result = await verifySingleContract(
      entry.name,
      entry.configKey,
      entry.address,
      entry.args,
      entry.contractPath,
      options.dryRun
    );

    results.push(result);

    if (result.status === "failed" && !options.continueOnError) {
      console.log(
        "\n❌ Stopping due to verification failure (set CONTINUE_ON_ERROR=true to continue)"
      );
      break;
    }

    if (!options.dryRun && result.status !== "skipped") {
      await delay(2_000);
    }
  }

  printSummary(results);

  if (results.some((result) => result.status === "failed")) {
    process.exitCode = 1;
  }
}

if (require.main === module) {
  void main().catch((error) => {
    console.error("\n❌ Verification script error:", error);
    process.exitCode = 1;
  });
}
