import {
  DeploymentOptions,
  DeploymentOrchestrator,
} from "./utils/DeploymentOrchestrator";
import { DEPLOYMENT_STEPS } from "./utils/deploymentConfig";

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

function parseDeployOptions(): DeploymentOptions {
  const options: DeploymentOptions = {
    skipVerification: parseBooleanEnv(
      process.env.DEPLOY_SKIP_VERIFICATION,
      false
    ),
    skipIfExists: parseBooleanEnv(process.env.DEPLOY_SKIP_IF_EXISTS, false),
    dryRun: parseBooleanEnv(process.env.DEPLOY_DRY_RUN, false),
  };

  if (process.env.DEPLOY_VERIFY !== undefined) {
    options.skipVerification = !parseBooleanEnv(
      process.env.DEPLOY_VERIFY,
      true
    );
  }

  if (process.env.DEPLOY_RESUME_FROM) {
    options.resumeFrom = process.env.DEPLOY_RESUME_FROM;
  }

  return options;
}

export async function main(): Promise<void> {
  const orchestrator = new DeploymentOrchestrator();
  await orchestrator.initialize();
  const deployOptions = parseDeployOptions();

  try {
    const deployedContracts = await orchestrator.deployAll(
      DEPLOYMENT_STEPS,
      deployOptions
    );

    await orchestrator.setupPermissions();

    if (!deployOptions.dryRun) {
      const isValid = await orchestrator.verify(deployedContracts);
      if (!isValid) {
        console.warn(
          "\n⚠️  Deployment verification found issues. Please review the output above."
        );
      }

      orchestrator.updateCollectionConfig();
      orchestrator.generateReport();

      console.log("\n" + "=".repeat(60));
      console.log("📋 Deployed Contract Addresses:");
      console.log("=".repeat(60));
      Object.entries(orchestrator.getDeployedAddresses()).forEach(
        ([name, address]) => {
          console.log(`  ${name}: ${address}`);
        }
      );
      console.log("=".repeat(60) + "\n");
    }

    console.log("✅ Deployment completed successfully!");
  } catch (error: any) {
    console.error("\n" + "=".repeat(60));
    console.error("❌ Deployment Failed");
    console.error("=".repeat(60));
    console.error(error?.message || error);
    process.exitCode = 1;
  }
}

if (require.main === module) {
  void main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}
