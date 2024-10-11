import { expect } from "chai";
import {
  createPublicClient,
  createTestClient,
  http,
  Account,
  getContract,
} from "viem";
import { hardhat } from "viem/chains";

import SysSetup from "../artifacts/contracts/SysSetup.sol/SysSetup.json";
import SysKeyGen from "../artifacts/contracts/SysKeyGen.sol/SysKeyGen.json";
import IdIssue from "../artifacts/contracts/IdIssue.sol/IdIssue.json";
import IdProve from "../artifacts/contracts/IdProve.sol/IdProve.json";
import IdVerify from "../artifacts/contracts/IdVerify.sol/IdVerify.json"; // renamed from IVVerify
import IdTrace from "../artifacts/contracts/IdTrace.sol/IdTrace.json";
import IdRecover from "../artifacts/contracts/IdRecover.sol/IdRecover.json";
import IPRevoke from "../artifacts/contracts/IPRevoke.sol/IPRevoke.json";

describe("Stateless Blockchain-Based Lightweight Identity Management Architecture (LSTIDM-SB)", function () {
  let sysSetupContract: any;
  let sysKeyGenContract: any;
  let idIssueContract: any;
  let idProveContract: any;
  let idVerifyContract: any; // renamed from IVVerify to IdVerify
  let idTraceContract: any;
  let idRecoverContract: any;
  let ipRevokeContract: any;
  let ownerAccount: Account;
  let addr1Account: Account;

  const identityHash1 = "0x" + Buffer.from("identity1").toString("hex");
  const identityHash2 = "0x" + Buffer.from("identity2").toString("hex");
  const proof1 = "0x" + Buffer.from("proof1").toString("hex");
  const proof2 = "0x" + Buffer.from("proof2").toString("hex");

  // Initialize the clients correctly
  const publicClient = createPublicClient({
    chain: hardhat,
    transport: http(),
  });
  const testClient = createTestClient({
    chain: hardhat,
    transport: http(),
    mode: 'test',
  });

    ownerAccount = {
      address: "0x0000000000000000000000000000000000000001",
      signMessage: async () => "0x",
      signTransaction: async () => "0x",
      signTypedData: async () => "0x",
      publicKey: "0x",
      address: "0x0000000000000000000000000000000000000000", // Replace with actual deployed address
    addr1Account = {
      address: "0x0000000000000000000000000000000000000002",
      signMessage: async () => "0x",
      signTransaction: async () => "0x",
      signTypedData: async () => "0x",
      publicKey: "0x",
    };
    addr1Account = { address: "0x0000000000000000000000000000000000000002" };
  });

  beforeEach(async function () {
    sysSetupContract = getContract({
      address: "DEPLOYED_ADDRESS", // Put the deployed address here
      abi: SysSetup.abi,
    });
    sysKeyGenContract = getContract({
      address: "DEPLOYED_ADDRESS", // Put the deployed address here
      abi: SysKeyGen.abi,
    });
    idIssueContract = getContract({
      address: "DEPLOYED_ADDRESS", // Put the deployed address here
      abi: IdIssue.abi,
    });
    idProveContract = getContract({
      address: "DEPLOYED_ADDRESS", // Put the deployed address here
      abi: IdProve.abi,
    });
    idVerifyContract = getContract({
      address: "DEPLOYED_ADDRESS", // Put the deployed address here
      abi: IdVerify.abi,
    });
    idTraceContract = getContract({
      address: "DEPLOYED_ADDRESS", // Put the deployed address here
    const systemOwner = await publicClient.readContract({
      address: sysSetupContract.address,
      abi: sysSetupContract.abi,
      functionName: "systemOwner",
      args: [],
    });
    });
    ipRevokeContract = getContract({
      address: "DEPLOYED_ADDRESS", // Put the deployed address here
      abi: IPRevoke.abi,
    });
  });

  it("should set up system parameters in SysSetup", async function () {
    const systemOwner = await publicClient.readContract({
      address: sysSetupContract.address,
      abi: sysSetupContract.abi,
      functionName: "systemOwner",
    });
    expect(systemOwner).to.equal(ownerAccount.address);
  });

  it("should generate keys for SysKeyGen", async function () {
    const privateKey = Buffer.from(
      crypto.getRandomValues(new Uint8Array(32))
    ).toString("hex");
    const publicKey = "0x" + Buffer.from(privateKey).toString("hex");

    await publicClient.writeContract({
      address: sysKeyGenContract.address,
      abi: sysKeyGenContract.abi,
      functionName: "generateKeys",
      args: [privateKey, publicKey],
      account: ownerAccount.address,
    });
    const storedPublicKey = await publicClient.readContract({
      address: sysKeyGenContract.address,
      abi: sysKeyGenContract.abi,
      functionName: "getPublicKey",
      args: [ownerAccount.address],
    });

    expect(storedPublicKey).to.equal(publicKey);
  });

  it("should issue an identity in IdIssue", async function () {
    await publicClient.writeContract({
      address: idIssueContract.address,
      abi: idIssueContract.abi,
      functionName: "issueIdentity",
      args: [identityHash1],
      account: ownerAccount.address,
    });
    const identity = await publicClient.readContract({
      address: idIssueContract.address,
      abi: idIssueContract.abi,
      functionName: "identities",
      args: [ownerAccount.address],
    });

    expect(identity.identityHash).to.equal(identityHash1);
    expect(identity.valid).to.be.true;
  });

  it("should submit and verify proof in IdProve and IdVerify", async function () {
    await publicClient.writeContract({
      address: idProveContract.address,
      abi: idProveContract.abi,
      functionName: "submitProof",
      args: [identityHash1, proof1],
      account: ownerAccount.address,
    });
    const proof = await publicClient.readContract({
      address: idProveContract.address,
      abi: idProveContract.abi,
      functionName: "getProof",
      args: [ownerAccount.address],
    });

    expect(proof.identityHash).to.equal(identityHash1);
    expect(proof.proof).to.equal(proof1);

    const isVerified = await publicClient.readContract({
      address: idVerifyContract.address,
      abi: idVerifyContract.abi,
      functionName: "verifyIdentity",
      args: [ownerAccount.address, identityHash1, proof1],
    });
    expect(isVerified).to.be.true;
  });

  it("should add and trace identity commitment in IdTrace", async function () {
    const commitment = "0x" + Buffer.from("commitment1").toString("hex");
    await publicClient.writeContract({
      address: idTraceContract.address,
      abi: idTraceContract.abi,
      functionName: "addCommitment",
      args: [ownerAccount.address, commitment],
      account: ownerAccount.address,
    });

    const tracedCommitment = await publicClient.readContract({
      address: idTraceContract.address,
      abi: idTraceContract.abi,
      functionName: "traceIdentity",
      args: [ownerAccount.address],
    });
    expect(tracedCommitment).to.equal(commitment);
  });

  it("should recover an identity in IdRecover", async function () {
    await publicClient.writeContract({
      address: idRecoverContract.address,
      abi: idRecoverContract.abi,
      functionName: "recoverIdentity",
      args: [ownerAccount.address, identityHash2],
      account: ownerAccount.address,
    });
    const identity = await publicClient.readContract({
      address: idIssueContract.address,
      abi: idIssueContract.abi,
      functionName: "identities",
      args: [ownerAccount.address],
    });

    expect(identity.identityHash).to.equal(identityHash2);
    expect(identity.valid).to.be.true;
  });

  it("should revoke an identity in IPRevoke", async function () {
    await publicClient.writeContract({
      address: ipRevokeContract.address,
      abi: ipRevokeContract.abi,
      functionName: "revokeIdentity",
      args: [ownerAccount.address],
      account: ownerAccount.address,
    });
    const identity = await publicClient.readContract({
      address: idIssueContract.address,
      abi: idIssueContract.abi,
      functionName: "identities",
      args: [ownerAccount.address],
    });

    expect(identity.valid).to.be.false;
  });
});
