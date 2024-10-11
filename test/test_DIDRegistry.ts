import { expect } from "chai";
import { ethers } from "hardhat";

describe("DIDRegistry", function () {
  let didRegistry: any;
  let accounts: any[];

  before(async () => {
    try {
      accounts = await ethers.getSigners();

      const DIDRegistry = await ethers.getContractFactory("DIDRegistry");
      didRegistry = await DIDRegistry.connect(accounts[1]).deploy(); // Deploying as the second account
      await didRegistry.waitForDeployment();

      const didRegistryAddress = await didRegistry.getAddress();

      expect(didRegistryAddress).to.not.be.undefined;
      expect(didRegistryAddress).to.not.equal(ethers.ZeroAddress);
      console.log("[LOG]: DIDRegistry deployed at:", didRegistryAddress);
    } catch (error) {
      console.error(
        "\n\n[ERROR]: !!!!! Contract Deployment Failed !!!!! \n",
        error
      );
      process.exit(1);
    }
  });

  it("should register a DID for a user", async function () {
    const firstName = "John";
    const lastName = "Doe";
    const email = "john.doe@example.com";
    const phoneNumber = "1234567890";

    // Generate DID from user's credentials
    const did = `did:example:${ethers.keccak256(
      new ethers.AbiCoder().encode(
        ["string", "string", "string", "string"],
        [firstName, lastName, email, phoneNumber]
      )
    )}`;

    // Print the DID
    console.log("[LOG]: Generated DID:", did);

    // Register the DID with a public key
    const publicKey = [
      {
        id: "did:example:123#keys-1",
        typeKey: "EcdsaSecp256k1VerificationKey2019",
        publicKeyHex: "0xYourPublicKeyHex", // Replace with actual public key hex
      },
    ];

    await didRegistry.registerDID(did, publicKey, []); // No services for now

    // Check that the DID is registered
    const { did: registeredDID, publicKeys } = await didRegistry.getDID(
      accounts[1].address // Use accounts[1] since it is the controller
    );
    expect(registeredDID).to.equal(did);
    expect(publicKeys.length).to.be.greaterThan(0);
  });

  it("should issue a Verifiable Credential", async function () {
    const credentialHash = ethers.keccak256(
      ethers.toUtf8Bytes("Credential for John Doe")
    );
    const issuanceDate = new Date().toISOString();

    await didRegistry.issueVC(
      accounts[1].address, // Use accounts[1] since it is the holder
      credentialHash,
      issuanceDate,
      "", // No expiration date for now
      []
    );

    // Verify the VC exists
    const exists = await didRegistry.verifyVC(
      credentialHash,
      accounts[1].address // Use accounts[1] since it is the holder
    );
    expect(exists).to.be.true;
  });

  it("should not allow duplicate registrations", async function () {
    const firstName = "John";
    const lastName = "Doe";
    const email = "john.doe@example.com";
    const phoneNumber = "1234567890";

    const did = `did:example:${ethers.keccak256(
      new ethers.AbiCoder().encode(
        ["string", "string", "string", "string"],
        [firstName, lastName, email, phoneNumber]
      )
    )}`;

    await expect(didRegistry.registerDID(did, [], [])).to.be.revertedWith(
      "DID already registered"
    );
  });

  it("should not allow unregistered users to get DID", async function () {
    const unregisteredUser = accounts[2].address; // Use another account that has not registered a DID

    // Attempt to get DID for an unregistered user
    await expect(didRegistry.getDID(unregisteredUser)).to.be.revertedWith(
      "DID not registered"
    );
  });

  it("should verify the Verifiable Credential", async function () {
    const credentialHash = ethers.keccak256(
      ethers.toUtf8Bytes("Credential for John Doe")
    );

    const exists = await didRegistry.verifyVC(
      credentialHash,
      accounts[1].address // Use accounts[1] since it is the holder
    );
    expect(exists).to.be.true;
  });
});
