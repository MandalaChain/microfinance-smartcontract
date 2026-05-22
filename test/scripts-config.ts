import { execFileSync } from "child_process";
import path from "path";
import { expect } from "chai";

const ANSI_ESCAPE_CODES = /\x1B\[[0-?]*[ -/]*[@-~]/g;

function runDeployLocalAddresses(): string {
  const scriptPath = path.resolve(__dirname, "../deploy-local.sh");
  const output = execFileSync(scriptPath, ["addresses"], {
    cwd: path.resolve(__dirname, ".."),
    encoding: "utf8",
  });

  return output.replace(ANSI_ESCAPE_CODES, "");
}

describe("deploy-local helper", function () {
  it("shows the current single-contract localhost deployment shape", function () {
    const output = runDeployLocalAddresses();

    expect(output).to.include("Deployed Localhost Contract");
    expect(output).to.include("Contract name:");
    expect(output).to.include("Configured local_address:");
    expect(output).to.not.include("kraflabLocalhost");
    expect(output).to.not.include("licenseLocalhost");
    expect(output).to.not.include("factoryLocalhost");
    expect(output).to.not.include("TagDeployerLocalhost");
    expect(output).to.not.include("OcpDeployerLocalhost");
    expect(output).to.not.include("OpnDeployerLocalhost");
    expect(output).to.not.include("escrowCoreLocalhost");
  });
});
