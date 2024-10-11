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

    console.log("[LOG]: Input - First Name:", firstName);
    console.log("[LOG]: Input - Last Name:", lastName);
    console.log("[LOG]: Input - Email:", email);
    console.log("[LOG]: Input - Phone Number:", phoneNumber);
    console.log("[LOG]: Expected Output - DID:", did);
    console.log("[LOG]: Actual Output - Registered DID:", registeredDID);
    console.log("[LOG]: Number of Public Keys:", publicKeys.length);

    expect(registeredDID).to.equal(did);
    expect(publicKeys.length).to.be.greaterThan(0);
  });

  it("should issue a new Verifiable Credential with claims", async function () {
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

    console.log("[LOG]: Claims for VC:");
    claims.forEach((claim) => {
      console.log(
        `[LOG]: Claim Type: ${claim.claimType}, Claim Value: ${claim.claimValue}`
      );
    });
    console.log("[LOG]: Expected Output - VC Exists: true");
    console.log("[LOG]: Actual Output - VC Exists:", exists);

    expect(exists).to.be.true;

    // Verify the claims
    const storedClaims = await didRegistry.getClaims(
      "https://www.w3.org/2018/credentials/v1",
      accounts[1].address,
      issuanceDate
    );
    console.log("[LOG]: Number of Stored Claims:", storedClaims.length);
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

    console.log("[LOG]: Attempting Duplicate Registration");
    console.log("[LOG]: Input - DID:", did);

    await expect(didRegistry.registerDID(did, [], [])).to.be.revertedWith(
      "DID already registered"
    );

    console.log("[LOG]: Expected Output - Error: 'DID already registered'");
  });

  it("should not allow unregistered users to get DID", async function () {
    const unregisteredUser = accounts[2].address; // Use another account that has not registered a DID

    console.log("[LOG]: Attempting to Get DID for Unregistered User");
    console.log("[LOG]: Input - Unregistered User Address:", unregisteredUser);

    await expect(didRegistry.getDID(unregisteredUser)).to.be.revertedWith(
      "DID not registered"
    );

    console.log("[LOG]: Expected Output - Error: 'DID not registered'");
  });

  it("should verify the Verifiable Credential", async function () {
    // Use the stored issuance date
    const exists = await didRegistry.verifyVC(
      "https://www.w3.org/2018/credentials/v1",
      accounts[1].address, // Use accounts[1] since it is the holder
      issuanceDate
    );

    console.log("[LOG]: Verifying VC with Existing Issuance Date");
    console.log("[LOG]: Expected Output - VC Exists: true");
    console.log("[LOG]: Actual Output - VC Exists:", exists);

    expect(exists).to.be.true;
  });

  it("should return false for non-existing Verifiable Credential", async function () {
    const invalidIssuanceDate = new Date().toISOString();

    const exists = await didRegistry.verifyVC(
      "https://www.w3.org/2018/credentials/v1",
      accounts[1].address, // Valid address but incorrect issuance date
      invalidIssuanceDate
    );

    console.log("[LOG]: Verifying VC with Invalid Issuance Date");
    console.log("[LOG]: Expected Output - VC Exists: false");
    console.log("[LOG]: Actual Output - VC Exists:", exists);

    expect(exists).to.be.false;
  });

  // it("should invalidate Verifiable Credential after expiration date", async function () {
  //   const claims = [
  //     { claimType: "First Name", claimValue: "Jane" },
  //     { claimType: "Last Name", claimValue: "Doe" },
  //   ];

  //   const expirationDate = new Date(Date.now() - 1000).toISOString(); // Set expiration to the past

  //   await didRegistry.issueVC(
  //     accounts[1].address,
  //     "https://www.w3.org/2018/credentials/v1",
  //     "VerifiableCredential",
  //     issuanceDate,
  //     expirationDate,
  //     claims,
  //     "0xProofSignature" // Replace with actual proof/signature
  //   );

  //   const exists = await didRegistry.verifyVC(
  //     "https://www.w3.org/2018/credentials/v1",
  //     accounts[1].address,
  //     expirationDate
  //   );

  //   console.log("[LOG]: Verifying VC after Expiration Date");
  //   console.log("[LOG]: Expected Output - VC Exists: false");
  //   console.log("[LOG]: Actual Output - VC Exists:", exists);

  //   expect(exists).to.be.false;
  // });

  it("should store and retrieve claims correctly", async function () {
    const firstName = "Alice";
    const lastName = "Smith";
    const email = "alice.smith@example.com";
    const phoneNumber = "0987654321";

    const claims = [
      { claimType: "First Name", claimValue: firstName },
      { claimType: "Last Name", claimValue: lastName },
      { claimType: "Email", claimValue: email },
      { claimType: "Phone", claimValue: phoneNumber },
    ];

    issuanceDate = new Date().toISOString(); // Generate new issuance date

    await didRegistry.issueVC(
      accounts[1].address,
      "https://www.w3.org/2018/credentials/v1",
      "VerifiableCredential",
      issuanceDate,
      "", // No expiration date for now
      claims,
      "0xProofSignature" // Replace with actual proof/signature
    );

    const storedClaims = await didRegistry.getClaims(
      "https://www.w3.org/2018/credentials/v1",
      accounts[1].address,
      issuanceDate
    );

    console.log("[LOG]: Verifying Stored Claims");
    console.log("[LOG]: Expected Number of Claims:", claims.length);
    console.log("[LOG]: Actual Number of Claims:", storedClaims.length);

    expect(storedClaims.length).to.equal(claims.length);

    for (let i = 0; i < claims.length; i++) {
      expect(storedClaims[i].claimType).to.equal(claims[i].claimType);
      expect(storedClaims[i].claimValue).to.equal(claims[i].claimValue);
    }
  });

  // it("should verify multiple VCs based on expiration", async function () {
  //   const claims = [
  //     { claimType: "First Name", claimValue: "John" },
  //     { claimType: "Last Name", claimValue: "Doe" },
  //     { claimType: "Email", claimValue: "john.doe@example.com" },
  //     { claimType: "Phone", claimValue: "1234567890" },
  //   ];

  //   // Issue first VC
  //   const issuanceDate1 = Math.floor(Date.now() / 1000); // Current time in seconds
  //   const expirationDate1 = Math.floor(Date.now() / 1000) + 3600; // Expires in 1 hour

  //   await didRegistry.issueVC(
  //     accounts[1].address,
  //     "https://www.w3.org/2018/credentials/v1",
  //     "VerifiableCredential",
  //     issuanceDate1,
  //     expirationDate1,
  //     claims,
  //     "0xProofSignature"
  //   );

  //   // Verify the first VC is valid immediately after issuance
  //   const existsValid1 = await didRegistry.verifyVC(
  //     "https://www.w3.org/2018/credentials/v1",
  //     accounts[1].address,
  //     issuanceDate1
  //   );
  //   expect(existsValid1).to.be.true;

  //   // Simulate expiration for the first VC
  //   await new Promise((resolve) => setTimeout(resolve, 3600 * 1000 + 1000)); // Wait for 1 hour and 1 second

  //   // Verify the first VC is expired
  //   const existsExpired1 = await didRegistry.verifyVC(
  //     "https://www.w3.org/2018/credentials/v1",
  //     accounts[1].address,
  //     issuanceDate1
  //   );
  //   expect(existsExpired1).to.be.false; // Should return false since it's expired

  //   // Check expiration before issuing second VC
  //   const existingVC = await didRegistry.getVC(
  //     accounts[1].address,
  //     "https://www.w3.org/2018/credentials/v1"
  //   );

  //   // Issue a new VC only if the existing one is expired
  //   if (existingVC.expirationDate < Math.floor(Date.now() / 1000)) {
  //     const issuanceDate2 = Math.floor(Date.now() / 1000); // Current time in seconds
  //     const expirationDate2 = Math.floor(Date.now() / 1000) + 1800; // Expires in 30 minutes

  //     // Issue second VC
  //     await didRegistry.issueVC(
  //       accounts[1].address,
  //       "https://www.w3.org/2018/credentials/v1",
  //       "VerifiableCredential",
  //       issuanceDate2,
  //       expirationDate2,
  //       claims,
  //       "0xProofSignature"
  //     );

  //     // Verify the second VC is valid
  //     const existsValid2 = await didRegistry.verifyVC(
  //       "https://www.w3.org/2018/credentials/v1",
  //       accounts[1].address,
  //       issuanceDate2
  //     );
  //     expect(existsValid2).to.be.true;
  //   } else {
  //     throw new Error("Cannot issue new VC as the existing one is still valid");
  //   }
  // });
});
