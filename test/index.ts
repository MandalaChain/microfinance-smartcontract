import chai, { expect } from "chai";
import ChaiAsPromised from "chai-as-promised";
import { ethers } from "hardhat";
import keccak256 from "keccak256";
import { utils, BigNumber } from "ethers";
import CollectionConfig from "../config/CollectionConfig";
import { NftContractType } from "../lib/NftContractProvider";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

chai.use(ChaiAsPromised);

describe(CollectionConfig.contractName, async function () {
  let contract!: NftContractType;
  let owner!: SignerWithAddress;
  let platform!: SignerWithAddress;
  let bankA!: SignerWithAddress;
  let bankB!: SignerWithAddress;
  let customer!: SignerWithAddress;
  let other!: SignerWithAddress;

  const nik = "123456789";
  const nikOther = "987654321";
  const codeBankA = "1234";
  const codeBankB = "5678";
  const codeBankOther = "8765";

  function hash32(identifier: string): string {
    return ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(["string"], [identifier])
    );
  }

  before(async function () {
    [owner, platform, bankA, bankB, customer, other] =
      await ethers.getSigners();

    const Contract = await ethers.getContractFactory(
      CollectionConfig.contractName
    );
    contract = (await Contract.deploy(
      await platform.getAddress(),
      "DataSharing",
      "1"
    )) as unknown as NftContractType;

    await contract.deployed();
  });

  // it("Contract deployment", async function () {
  //   const Contract = await ethers.getContractFactory(
  //     CollectionConfig.contractName
  //   );
  //   contract = (await Contract.deploy(
  //     await platform.getAddress()
  //   )) as unknown as NftContractType;

  //   await contract.deployed();
  //   domain.verifyingContract = contract.address;
  // });

  it("Check owner address", async function () {
    expect(await contract.owner()).to.equal(await owner.getAddress());
    await expect(
      contract.connect(other).setPlatform(await other.getAddress())
    ).to.be.rejectedWith(
      `OwnableUnauthorizedAccount("${await other.getAddress()}")`
    );
  });

  it("Initial Data", async function () {
    expect(await contract.getDebtor(hash32(nik))).to.be.equal(
      ethers.constants.AddressZero
    );

    expect(await contract.getCreditor(hash32(codeBankA))).to.be.equal(
      ethers.constants.AddressZero
    );

    await expect(
      contract.getDebtorDataActiveCreditors(hash32(nik))
    ).to.be.rejectedWith("NikNeedRegistered");

    await expect(
      contract.getActiveCreditorsByStatus(hash32(nik), BigNumber.from(0))
    ).to.be.rejectedWith("NikNeedRegistered");

    await expect(
      contract.getActiveCreditorsByStatus(hash32(nik), BigNumber.from(1))
    ).to.be.rejectedWith("NikNeedRegistered");

    await expect(
      contract.getActiveCreditorsByStatus(hash32(nik), BigNumber.from(2))
    ).to.be.rejectedWith("NikNeedRegistered");
  });

  it("Check only platform", async function () {
    await expect(
      contract
        .connect(other)
        .addDebtor(hash32(nik), await customer.getAddress())
    ).to.be.rejectedWith("AddressNotEligible");

    await expect(
      contract
        .connect(other)
        .functions["addDebtor(bytes32,address)"](
          hash32(codeBankA),
          await bankA.getAddress()
        )
    ).to.be.rejectedWith("AddressNotEligible");

    await expect(
      contract
        .connect(other)
        .functions[
          "addCreditor(address,bytes32,string,string,string,string,string)"
        ](
          await bankA.getAddress(),
          hash32(codeBankA),
          "institutionCode",
          "institutionName",
          "approvalDate",
          "signerName",
          "signerPosition"
        )
    ).to.be.rejectedWith("AddressNotEligible");

    await expect(
      contract.connect(other).removeDebtor(hash32(nik))
    ).to.be.rejectedWith("AddressNotEligible");

    await expect(
      contract.connect(other).removeCreditor(hash32(codeBankA))
    ).to.be.rejectedWith("AddressNotEligible");

    await expect(
      contract
        .connect(other)
        .addDebtorToCreditor(
          hash32(nik),
          hash32(codeBankA),
          "",
          "",
          "",
          "",
          "",
          ""
        )
    ).to.be.rejectedWith("AddressNotEligible");
  });

  it("Error adding creditor using zero hash", async function () {
    await expect(
      contract
        .connect(platform)
        .functions[
          "addCreditor(address,bytes32,string,string,string,string,string)"
        ](
          await bankA.getAddress(),
          ethers.utils.hexZeroPad("0x0", 32),
          "institutionCode",
          "institutionName",
          "approvalDate",
          "signerName",
          "signerPosition"
        )
    ).to.be.rejectedWith("InvalidHash");
  });

  it("Error adding creditor using zero address", async function () {
    await expect(
      contract
        .connect(platform)
        .functions[
          "addCreditor(address,bytes32,string,string,string,string,string)"
        ](
          ethers.constants.AddressZero,
          hash32(codeBankA),
          "institutionCode",
          "institutionName",
          "approvalDate",
          "signerName",
          "signerPosition"
        )
    ).to.be.rejectedWith("InvalidAddress");
  });

  it("Success adding creditor A and retrive event emit using EIP-712 gasless transaction", async function () {
    const creditorAddress = await bankA.getAddress();
    const creditorCode = hash32(codeBankA);
    const institutionCode = "INSTITUTION_CODE";
    const institutionName = "Institution Name";
    const approvalDate = "2025-01-24";
    const signerName = "Signer Name";
    const signerPosition = "Signer Position";

    // ✅ Get correct chainId
    const network = await ethers.provider.getNetwork();

    // ✅ Define EIP-712 domain
    const domain = {
      name: "DataSharing",
      version: "1",
      chainId: network.chainId,
      verifyingContract: contract.address,
    };

    // ✅ Fetch correct nonce
    const nonce = await contract.nonces(await platform.getAddress());

    // ✅ Encode function call correctly
    const functionCall = contract.interface.encodeFunctionData(
      contract.interface.getFunction(
        "addCreditor(address,bytes32,string,string,string,string,string)"
      ),
      [
        creditorAddress,
        creditorCode,
        institutionCode,
        institutionName,
        approvalDate,
        signerName,
        signerPosition,
      ]
    );

    // ✅ Prepare message for signing
    const message = {
      from: await platform.getAddress(),
      nonce: Number(nonce),
      functionCall: functionCall,
    };

    // ✅ Sign meta-transaction
    const signature = await platform._signTypedData(
      domain,
      {
        MetaTransaction: [
          { name: "from", type: "address" },
          { name: "nonce", type: "uint256" },
          { name: "functionCall", type: "bytes" },
        ],
      },
      message
    );

    // ✅ Verify signature before sending
    const recoveredSigner = ethers.utils.verifyTypedData(
      domain,
      {
        MetaTransaction: [
          { name: "from", type: "address" },
          { name: "nonce", type: "uint256" },
          { name: "functionCall", type: "bytes" },
        ],
      },
      message,
      signature
    );

    expect(recoveredSigner).to.equal(await platform.getAddress());

    // ✅ Execute meta-transaction
    let receipt;
    try {
      const tx = await contract
        .connect(platform)
        .executeMetaTransaction(
          message.from,
          message.nonce,
          message.functionCall,
          signature
        );
      receipt = await tx.wait();
    } catch (error: any) {
      console.error("Transaction failed! Revert Reason:", error);
      if (error.data) {
        console.error(
          "Decoded Revert Reason:",
          ethers.utils.toUtf8String(error.data)
        );
      }
    }

    // ✅ Check for event emission
    const event = receipt.events?.find(
      (e: { event: string }) => e.event === "CreditorAddedWithMetadata"
    );

    expect(event).to.not.be.undefined;
    expect(event.args.creditorCode).to.equal(creditorCode);
    expect(event.args.institutionCode).to.equal(institutionCode);
    expect(event.args.institutionName).to.equal(institutionName);
    expect(event.args.approvalDate).to.equal(approvalDate);
    expect(event.args.signerName).to.equal(signerName);
    expect(event.args.signerPosition).to.equal(signerPosition);
  });

  it("Success retrive public key credtiro A from code creditor A", async function () {
    expect(await contract.getCreditor(hash32(codeBankA))).to.be.equal(
      await bankA.getAddress()
    );
  });

  it("Error adding creditor A same code creditor cause already exist", async function () {
    await expect(
      contract
        .connect(platform)
        .functions[
          "addCreditor(address,bytes32,string,string,string,string,string)"
        ](
          await bankA.getAddress(),
          hash32(codeBankA),
          "institutionCode",
          "institutionName",
          "approvalDate",
          "signerName",
          "signerPosition"
        )
    ).to.be.rejectedWith("AlreadyExist");
  });

  it("Error create wallet for debtor because zero hash", async function () {
    await expect(
      contract
        .connect(platform)
        .addDebtor(
          ethers.utils.hexZeroPad("0x0", 32),
          await customer.getAddress()
        )
    ).to.be.rejectedWith("InvalidHash");
  });

  it("Error create wallet for debtor because wallet to set it up is zero address", async function () {
    await expect(
      contract
        .connect(platform)
        .addDebtor(hash32(nik), ethers.constants.AddressZero)
    ).to.be.rejectedWith("InvalidAddress");
  });

  it("Success create wallet for debtor and mapping it to storage contract", async function () {
    await contract
      .connect(platform)
      .addDebtor(hash32(nik), await customer.getAddress());
  });

  it("Success retrive wallet public key from NIK debtor", async function () {
    expect(await contract.getDebtor(hash32(nik))).to.be.equal(
      await customer.getAddress()
    );
  });

  it("Error create wallet for debtor because already exist", async function () {
    await expect(
      contract
        .connect(platform)
        .addDebtor(hash32(nik), await customer.getAddress())
    ).to.be.rejectedWith("AlreadyExist");
  });

  it("Error zero hash NIK and code creditor by adding Debitor to active customer for creditor A", async function () {
    await expect(
      contract
        .connect(platform)
        .addDebtorToCreditor(
          ethers.utils.hexZeroPad("0x0", 32),
          ethers.utils.hexZeroPad("0x0", 32),
          "",
          "",
          "",
          "",
          "",
          ""
        )
    ).to.be.rejectedWith("InvalidHash");
  });

  it("Error zero address other creditor from code creditor by adding Debitor to active customer for other creditor cause not registered", async function () {
    await expect(
      contract
        .connect(platform)
        .addDebtorToCreditor(
          hash32(nik),
          hash32(codeBankOther),
          "",
          "",
          "",
          "",
          "",
          ""
        )
    ).to.be.rejectedWith("NotEligible");
  });

  it("Success adding Debitor to active customer for creditor A and retrive event emit", async function () {
    const nikDebtor = hash32(nik);
    const name = "Name Debtor";
    const creditorCode = hash32(codeBankA);
    const creditorName = "Creditor A";
    const applicationDate = "10-10-2010";
    const approvalDate = "26-01-2025";
    const urlKTP = "http://url-ktp-test";
    const urlApproval = "http://url-approval-test";

    const tx = await contract
      .connect(platform)
      .addDebtorToCreditor(
        nikDebtor,
        creditorCode,
        name,
        creditorName,
        applicationDate,
        approvalDate,
        urlKTP,
        urlApproval
      );

    const receipt = await tx.wait();
    const event = receipt.events?.find(
      (e: { event: string }) => e.event === "DebtorAddedWithMetadata"
    );

    expect(event).to.not.be.undefined;
    expect(event.args.nik).to.equal(nikDebtor);
    expect(event.args.name).to.equal(name);
    expect(event.args.creditorCode).to.equal(creditorCode);
    expect(event.args.creditorName).to.equal(creditorName);
    expect(event.args.applicationDate).to.equal(applicationDate);
    expect(event.args.approvalDate).to.equal(approvalDate);
    expect(event.args.urlKTP).to.equal(urlKTP);
    expect(event.args.urlApproval).to.equal(urlApproval);
  });

  it("Error adding Debitor to active customer for creditor A cause already registered", async function () {
    await expect(
      contract
        .connect(platform)
        .addDebtorToCreditor(
          hash32(nik),
          hash32(codeBankA),
          "",
          "",
          "",
          "",
          "",
          ""
        )
    ).to.be.rejectedWith("AlreadyExist");
  });

  it("Retrive ceredtior A as active creditor from storage contract", async function () {
    const [creditors, statuses] = await contract.getDebtorDataActiveCreditors(
      hash32(nik)
    );

    expect(creditors).to.deep.equal([await bankA.getAddress()]);
    expect(statuses).to.deep.equal([2]);
  });

  it("Success adding creditor B and retrive event emit", async function () {
    const creditorAddress = await bankB.getAddress();
    const creditorCode = hash32(codeBankB);
    const institutionCode = "INSTITUTION_CODE";
    const institutionName = "Institution Name";
    const approvalDate = "2025-01-24";
    const signerName = "Signer Name";
    const signerPosition = "Signer Position";

    const tx = await contract
      .connect(platform)
      .functions[
        "addCreditor(address,bytes32,string,string,string,string,string)"
      ](
        creditorAddress,
        creditorCode,
        institutionCode,
        institutionName,
        approvalDate,
        signerName,
        signerPosition
      );

    const receipt = await tx.wait();
    const event = receipt.events?.find(
      (e: { event: string }) => e.event === "CreditorAddedWithMetadata"
    );
    expect(event).to.not.be.undefined;
    expect(event.args.creditorCode).to.equal(creditorCode);
    expect(event.args.institutionCode).to.equal(institutionCode);
    expect(event.args.institutionName).to.equal(institutionName);
    expect(event.args.approvalDate).to.equal(approvalDate);
    expect(event.args.signerName).to.equal(signerName);
    expect(event.args.signerPosition).to.equal(signerPosition);
  });

  it("Should Error When creditor ask for data sharing from not registered creditor", async function () {
    await expect(
      contract
        .connect(other)
        .functions["requestDelegation(bytes32,bytes32,bytes32)"](
          hash32(nik),
          hash32(codeBankOther),
          hash32(codeBankA)
        )
    ).to.be.rejectedWith("NotEligible");

    await expect(
      contract
        .connect(bankB)
        .functions["requestDelegation(bytes32,bytes32,bytes32)"](
          hash32(nik),
          hash32(codeBankB),
          hash32(codeBankOther)
        )
    ).to.be.rejectedWith("NotEligible");
  });

  it("Should Error When consumer ask for data sharing from wrong provider of debtor data", async function () {
    await expect(
      contract
        .connect(platform)
        .functions["requestDelegation(bytes32,bytes32,bytes32)"](
          hash32(nik),
          hash32(codeBankA),
          hash32(codeBankB)
        )
    ).to.be.rejectedWith("ProviderNotEligible");
  });

  it("Should Error When consumer ask for data sharing from provider but the debtor not registered", async function () {
    await expect(
      contract
        .connect(platform)
        .functions["requestDelegation(bytes32,bytes32,bytes32)"](
          hash32(nikOther),
          hash32(codeBankB),
          hash32(codeBankA)
        )
    ).to.be.rejectedWith("NikNeedRegistered");
  });

  it("Should Error When cosumer ask for data sharing from provider but the wallet runner is not same as consumer", async function () {
    await expect(
      contract
        .connect(bankA)
        .functions["requestDelegation(bytes32,bytes32,bytes32)"](
          hash32(nik),
          hash32(codeBankB),
          hash32(codeBankA)
        )
    ).to.be.rejectedWith("AddressNotEligible");
  });

  // it("Success request sharing data and retrive the event emit", async function () {
  //   const nikDebtor = hash32(nik);
  //   const creditorConsumerCode = hash32(codeBankB);
  //   const creditorProviderCode = hash32(codeBankA);
  //   const requestId = "request id";
  //   const transactionId = "transaction id";
  //   const referenceId = "reference id";
  //   const requestDate = "request data";

  //   const tx = await contract
  //     .connect(bankB)
  //     .functions[
  //       "requestDelegation(bytes32,bytes32,bytes32,string,string,string,string)"
  //     ](
  //       nikDebtor,
  //       creditorConsumerCode,
  //       creditorProviderCode,
  //       requestId,
  //       transactionId,
  //       referenceId,
  //       requestDate
  //     );

  //   const receipt = await tx.wait();
  //   const event = receipt.events?.find(
  //     (e: { event: string }) => e.event === "DelegationRequestedMetadata"
  //   );
  //   expect(event).to.not.be.undefined;
  //   expect(event.args.nik).to.equal(nikDebtor);
  //   expect(event.args.requestId).to.equal(requestId);
  //   expect(event.args.creditorConsumerCode).to.equal(creditorConsumerCode);
  //   expect(event.args.creditorProviderCode).to.equal(creditorProviderCode);
  //   expect(event.args.transactionId).to.equal(transactionId);
  //   expect(event.args.referenceId).to.equal(referenceId);
  //   expect(event.args.requestDate).to.equal(requestDate);
  // });
  it("Success request sharing data and retrive the event emit", async function () {
    const nikDebtor = hash32(nik);
    const creditorConsumerCode = hash32(codeBankB);
    const creditorProviderCode = hash32(codeBankA);
    const requestId = "request id";
    const transactionId = "transaction id";
    const referenceId = "reference id";
    const requestDate = "request data";

    // ✅ Get correct chainId
    const network = await ethers.provider.getNetwork();

    // ✅ Define EIP-712 domain
    const domain = {
      name: "DataSharing",
      version: "1",
      chainId: network.chainId,
      verifyingContract: contract.address,
    };

    // ✅ Fetch correct nonce
    const nonce = await contract.nonces(await platform.getAddress());

    // ✅ Encode function call correctly
    const functionCall = contract.interface.encodeFunctionData(
      contract.interface.getFunction(
        "requestDelegation(bytes32,bytes32,bytes32,string,string,string,string)"
      ),
      [
        nikDebtor,
        creditorConsumerCode,
        creditorProviderCode,
        requestId,
        transactionId,
        referenceId,
        requestDate,
      ]
    );

    // ✅ Prepare message for signing
    const message = {
      from: await platform.getAddress(),
      nonce: Number(nonce),
      functionCall: functionCall,
    };

    // ✅ Sign meta-transaction
    const signature = await platform._signTypedData(
      domain,
      {
        MetaTransaction: [
          { name: "from", type: "address" },
          { name: "nonce", type: "uint256" },
          { name: "functionCall", type: "bytes" },
        ],
      },
      message
    );

    // ✅ Verify signature before sending
    const recoveredSigner = ethers.utils.verifyTypedData(
      domain,
      {
        MetaTransaction: [
          { name: "from", type: "address" },
          { name: "nonce", type: "uint256" },
          { name: "functionCall", type: "bytes" },
        ],
      },
      message,
      signature
    );

    expect(recoveredSigner).to.equal(await platform.getAddress());

    // ✅ Execute meta-transaction
    let receipt;
    try {
      const tx = await contract
        .connect(platform)
        .executeMetaTransaction(
          message.from,
          message.nonce,
          message.functionCall,
          signature
        );
      receipt = await tx.wait();
    } catch (error: any) {
      console.error("Transaction failed! Revert Reason:", error);
      if (error.data) {
        console.error(
          "Decoded Revert Reason:",
          ethers.utils.toUtf8String(error.data)
        );
      }
    }

    const event = receipt.events?.find(
      (e: { event: string }) => e.event === "DelegationRequestedMetadata"
    );
    expect(event).to.not.be.undefined;
    expect(event.args.nik).to.equal(nikDebtor);
    expect(event.args.requestId).to.equal(requestId);
    expect(event.args.creditorConsumerCode).to.equal(creditorConsumerCode);
    expect(event.args.creditorProviderCode).to.equal(creditorProviderCode);
    expect(event.args.transactionId).to.equal(transactionId);
    expect(event.args.referenceId).to.equal(referenceId);
    expect(event.args.requestDate).to.equal(requestDate);
  });

  it("Should Error When consumer ask for data sharing twice", async function () {
    await expect(
      contract
        .connect(platform)
        .functions["requestDelegation(bytes32,bytes32,bytes32)"](
          hash32(nik),
          hash32(codeBankB),
          hash32(codeBankA)
        )
    ).to.be.rejectedWith("RequestAlreadyExist");
  });

  it("Retrive ceredtiors as active creditor from storage contract", async function () {
    const [creditors, statuses] = await contract.getDebtorDataActiveCreditors(
      hash32(nik)
    );

    expect(creditors).to.deep.equal([
      await bankA.getAddress(),
      await bankB.getAddress(),
    ]); // bank a and bank b
    expect(statuses).to.deep.equal([2, 3]); // approve and pending
  });

  it("Should Error When provider approve delegate for data sharing from consumer but the wallet runner is not same as provider", async function () {
    await expect(
      contract
        .connect(other)
        .delegate(hash32(nik), hash32(codeBankB), hash32(codeBankA), 1)
    ).to.be.rejectedWith("AddressNotEligible");
  });

  it("Success approve delegaton for data sharing", async function () {
    const tx = await contract
      .connect(platform)
      .delegate(hash32(nik), hash32(codeBankB), hash32(codeBankA), 2);

    const receipt = await tx.wait();
    const event = receipt.events?.find(
      (e: { event: string }) => e.event === "Delegate"
    );
    expect(event).to.not.be.undefined;
    expect(event.args.nik).to.equal(hash32(nik));
    expect(event.args.creditorConsumerCode).to.equal(hash32(codeBankB));
    expect(event.args.creditorProviderCode).to.equal(hash32(codeBankA));
    expect(event.args.status).to.equal(2);
  });

  it("Shoudl error approving delegation twice", async function () {
    await expect(
      contract
        .connect(platform)
        .delegate(hash32(nik), hash32(codeBankB), hash32(codeBankA), 2)
    ).to.be.rejectedWith("InvalidStatusApproveRequest");
  });
});
