import { expect } from "chai";
import { ethers } from "hardhat";

describe("StatelessBlockchainWithIPFS", function () {
  let StatelessBlockchainWithIPFS: any;
  let statelessBlockchain: any;

  const modulus = 2357; // Example modulus (replace with actual primes)
  const accumulatorBase = 65537; // Example base

  beforeEach(async () => {
    StatelessBlockchainWithIPFS = await ethers.getContractFactory(
      "StatelessBlockchainWithIPFS"
    );
    statelessBlockchain = await StatelessBlockchainWithIPFS.deploy(
      modulus,
      accumulatorBase
    );
    await statelessBlockchain.waitForDeployment(); // Use deployed() instead of waitForDeployment()
    console.log(
      "StatelessBlockchainWithIPFS deployed to: ",
      statelessBlockchain.address
    );
    console.log("Modulus: ", modulus);
    console.log("Accumulator base: ", accumulatorBase);
  });

  it("should add an identity and emit the event", async () => {
    const identityHash = ethers.keccak256(ethers.toUtf8Bytes("identity1"));
    const ipfsCID = "Qm12345";

    console.log("Identity hash: ", identityHash);
    console.log("IPFS CID: ", ipfsCID);

    await expect(statelessBlockchain.addIdentity(identityHash, ipfsCID))
      .to.emit(statelessBlockchain, "IdentityAdded")
      .withArgs(identityHash, ipfsCID);

    const storedCID = await statelessBlockchain.getIPFSCID(identityHash);
    console.log("Stored CID: ", storedCID);
    expect(storedCID).to.equal(ipfsCID);

    const blockCount = await statelessBlockchain.blockchain.length; // Fixed here
    expect(blockCount).to.equal(1);
  });

  it("should revoke an identity and emit the event", async () => {
    const identityHash = ethers.keccak256(ethers.toUtf8Bytes("identity2"));
    const ipfsCID = "Qm67890";

    await statelessBlockchain.addIdentity(identityHash, ipfsCID);

    await expect(statelessBlockchain.revokeIdentity(identityHash))
      .to.emit(statelessBlockchain, "IdentityRevoked")
      .withArgs(
        identityHash,
        await statelessBlockchain.identityProofs(identityHash)
      );

    const isRevoked = await statelessBlockchain.revokedIdentities(identityHash);
    expect(isRevoked).to.be.true;

    const blockCount = await statelessBlockchain.blockchain.callStatic.length; // Fixed here
    expect(blockCount).to.equal(1);
  });

  it("should verify an identity", async () => {
    const identityHash = ethers.keccak256(ethers.toUtf8Bytes("identity3"));
    const ipfsCID = "Qmabcdef";

    await statelessBlockchain.addIdentity(identityHash, ipfsCID);

    const witness = await statelessBlockchain.identityProofs(identityHash);
    const isValid = await statelessBlockchain.verifyIdentity(
      identityHash,
      witness
    );

    expect(isValid).to.be.true;
  });

  it("should not verify a revoked identity", async () => {
    const identityHash = ethers.keccak256(ethers.toUtf8Bytes("identity4"));
    const ipfsCID = "Qmghijkl";

    await statelessBlockchain.addIdentity(identityHash, ipfsCID);
    await statelessBlockchain.revokeIdentity(identityHash);

    const witness = await statelessBlockchain.identityProofs(identityHash);
    await expect(
      statelessBlockchain.verifyIdentity(identityHash, witness)
    ).to.be.revertedWith("Identity is revoked");
  });

  it("should get the latest accumulator", async () => {
    const latestAccumulator = await statelessBlockchain.getLatestAccumulator();
    expect(latestAccumulator).to.equal(0); // Initially, it should be the default value
  });
});
