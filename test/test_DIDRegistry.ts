import { expect } from "chai";
import { ethers } from "hardhat";

describe("DIDRegistry", function () {
  let didRegistry: any;
  let accounts: any[];
  let issuanceDate: string; // Store issuance date

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

  it("should issue a Verifiable Credential with claims", async function () {
    const firstName = "John";
    const lastName = "Doe";
    const email = "john.doe@example.com";
    const phoneNumber = "1234567890";

    // Create claims for the Verifiable Credential
    const claims = [
      { claimType: "First Name", claimValue: firstName },
      { claimType: "Last Name", claimValue: lastName },
      { claimType: "Email", claimValue: email },
      { claimType: "Phone", claimValue: phoneNumber },
    ];

    issuanceDate = new Date().toISOString(); // Store issuance date

    await didRegistry.issueVC(
      accounts[1].address, // Use accounts[1] since it is the holder
      "https://www.w3.org/2018/credentials/v1",
      "VerifiableCredential",
      issuanceDate,
      "", // No expiration date for now
      claims,
      "0xProofSignature" // Replace with actual proof/signature
    );

    // Verify the VC exists
    const exists = await didRegistry.verifyVC(
      "https://www.w3.org/2018/credentials/v1",
      accounts[1].address, // Use accounts[1] since it is the holder
      issuanceDate
    );
    expect(exists).to.be.true;

    // Verify the claims
    const storedClaims = await didRegistry.getClaims(
      "https://www.w3.org/2018/credentials/v1",
      accounts[1].address,
      issuanceDate
    );
    expect(storedClaims.length).to.equal(claims.length);
    for (let i = 0; i < claims.length; i++) {
      expect(storedClaims[i].claimType).to.equal(claims[i].claimType);
      expect(storedClaims[i].claimValue).to.equal(claims[i].claimValue);
    }
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
    // Use the stored issuance date
    const exists = await didRegistry.verifyVC(
      "https://www.w3.org/2018/credentials/v1",
      accounts[1].address, // Use accounts[1] since it is the holder
      issuanceDate
    );
    expect(exists).to.be.true;
  });
});
