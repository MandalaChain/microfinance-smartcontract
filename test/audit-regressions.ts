import chai, { expect } from "chai";
import ChaiAsPromised from "chai-as-promised";
import { ethers } from "hardhat";
import { keccak256, toUtf8Bytes } from "ethers";

chai.use(ChaiAsPromised);

describe("audit regressions", function () {
  let contract: any;
  let owner: any;
  let platform: any;
  let debtor: any;
  let debtorTwo: any;
  let bankA: any;
  let bankB: any;
  let bankC: any;
  let attacker: any;

  const nikOne = hash32("audit-nik-one");
  const nikTwo = hash32("audit-nik-two");
  const codeBankA = hash32("audit-bank-a");
  const codeBankB = hash32("audit-bank-b");
  const codeBankC = hash32("audit-bank-c");

  function hash32(identifier: string): string {
    return keccak256(toUtf8Bytes(identifier));
  }

  async function deployContract() {
    [owner, platform, debtor, debtorTwo, bankA, bankB, bankC, attacker] =
      await ethers.getSigners();

    const Contract = await ethers.getContractFactory("DataSharing");
    contract = await Contract.connect(owner).deploy();
    await contract.waitForDeployment();
    await contract.connect(owner).setPlatform(await platform.getAddress());
  }

  async function registerCreditor(code: string, signer: any) {
    await contract
      .connect(platform)
      ["addCreditor(bytes32,address)"](code, await signer.getAddress());
  }

  async function registerDebtor(nik: string, signer: any) {
    await contract
      .connect(platform)
      .addDebtor(nik, await signer.getAddress());
  }

  async function addDebtorToCreditor(nik: string, creditorCode: string) {
    await contract
      .connect(platform)
      .addDebtorToCreditor(nik, creditorCode, "", "", "", "", "", "");
  }

  async function activeCreditors(nik: string): Promise<string[]> {
    return contract.getActiveCreditors(nik);
  }

  async function expectEvent(txPromise: Promise<any>, eventName: string) {
    const tx = await txPromise;
    const receipt = await tx.wait();
    if (!receipt) {
      throw new Error("missing receipt");
    }

    for (const log of receipt.logs) {
      try {
        const parsed = contract.interface.parseLog(log);
        if (parsed?.name === eventName) {
          return parsed;
        }
      } catch {
        // Ignore logs from other contracts.
      }
    }

    throw new Error(`event ${eventName} not found`);
  }

  beforeEach(async function () {
    await deployContract();
  });

  it("rejects package purchase events from non-platform callers", async function () {
    await expect(
      contract
        .connect(attacker)
        .purchasePackage("BANK", "2026-05-22", "INV-1", 1, 2, "2026-05-22", "2026-06-22", 100)
    ).to.be.rejectedWith("AddressNotEligible");
  });

  it("emits an event when the plain addDebtor path registers a debtor", async function () {
    const event = await expectEvent(
      contract.connect(platform).addDebtor(nikOne, await debtor.getAddress()),
      "DebtorAdded"
    );

    expect(event.args.nik).to.equal(nikOne);
    expect(event.args.debtorAddress).to.equal(await debtor.getAddress());
  });

  it("adds both provider and consumer as active creditors during processAction", async function () {
    await registerDebtor(nikOne, debtor);
    await registerCreditor(codeBankB, bankB);
    await registerCreditor(codeBankC, bankC);

    await contract
      .connect(platform)
      .processAction(nikOne, codeBankC, codeBankB, "metadata");

    expect(await activeCreditors(nikOne)).to.deep.equal([
      await bankB.getAddress(),
      await bankC.getAddress(),
    ]);
  });

  it("rejects duplicate processAction provider approvals instead of duplicating creditors", async function () {
    await registerDebtor(nikOne, debtor);
    await registerCreditor(codeBankB, bankB);
    await registerCreditor(codeBankC, bankC);

    await contract
      .connect(platform)
      .processAction(nikOne, codeBankC, codeBankB, "metadata");

    await expect(
      contract
        .connect(platform)
        .processAction(nikOne, codeBankC, codeBankB, "metadata")
    ).to.be.rejectedWith("AlreadyExist");

    expect(await activeCreditors(nikOne)).to.deep.equal([
      await bankB.getAddress(),
      await bankC.getAddress(),
    ]);
  });

  it("scopes delegate requests by NIK for the same consumer and provider", async function () {
    await registerDebtor(nikOne, debtor);
    await registerDebtor(nikTwo, debtorTwo);
    await registerCreditor(codeBankA, bankA);
    await registerCreditor(codeBankB, bankB);
    await addDebtorToCreditor(nikOne, codeBankA);
    await addDebtorToCreditor(nikTwo, codeBankA);

    await contract
      .connect(platform)
      ["delegate(bytes32,bytes32,bytes32)"](nikOne, codeBankB, codeBankA);
    await contract
      .connect(platform)
      ["delegate(bytes32,bytes32,bytes32)"](nikTwo, codeBankB, codeBankA);

    expect(await activeCreditors(nikTwo)).to.deep.equal([
      await bankA.getAddress(),
      await bankB.getAddress(),
    ]);
  });

  it("clears debtor creditor state when a debtor is removed", async function () {
    await registerDebtor(nikOne, debtor);
    await registerCreditor(codeBankA, bankA);
    await addDebtorToCreditor(nikOne, codeBankA);

    await contract.connect(platform).removeDebtor(nikOne);
    await registerDebtor(nikOne, debtor);

    expect(await activeCreditors(nikOne)).to.deep.equal([]);
  });
});
