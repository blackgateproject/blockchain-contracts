import { expect } from "chai";
import { ethers } from "hardhat";

describe.only("StatelessBlockchain", function () {
  let accumulatorContract: any;
  let accounts: any[];
  const btiSze = 32; // Example modulus for RSA operations; adjust as needed

  before(async () => {
    accounts = await ethers.getSigners();
    const StatelessBlockchain = await ethers.getContractFactory(
      "StatelessBlockchain"
    );
    accumulatorContract = await StatelessBlockchain.deploy(btiSze);
    await accumulatorContract.waitForDeployment();

    const accumulatorContractAddress = await accumulatorContract.getAddress();
    expect(accumulatorContractAddress).to.not.be.undefined;
    expect(accumulatorContractAddress).to.not.equal(ethers.ZeroAddress);
    console.log(
      "[LOG]: StatelessBlockchain deployed at:",
      accumulatorContractAddress
    );
  });

  it("should add a new identity to the accumulator", async function () {
    const modNVal = await accumulatorContract.modN();
    console.log("[LOG]: Current modN Value:", modNVal);
    const currentACCVal = await accumulatorContract.accumulator();
    console.log("[LOG]: Current accumulator Value:", currentACCVal);

    const identityCredential = 12345;
    console.log("[LOG]: Adding identity credential:", identityCredential);

    const tx = await accumulatorContract.addIdentity(identityCredential);
    const receipt = await tx.wait();

    // Log Debug event info
    const debugEvent = receipt.events?.find(
      (event: any) => event.event === "Debug"
    );
    if (debugEvent) {
      const [hashedCredential, newAccumulator] = debugEvent.args;
      console.log(
        "[DEBUG LOG]: Hashed Credential:",
        hashedCredential.toString()
      );
      console.log(
        "[DEBUG LOG]: New Accumulator Value:",
        newAccumulator.toString()
      );
    }

    const newACCVal = await accumulatorContract.accumulator();
    console.log("[LOG]: New accumulator Value:", newACCVal);

    expect(newACCVal).to.not.equal(currentACCVal);
  });

  //   it("should remove an existing identity from the accumulator", async function () {

  //   });

  //   it("should verify an added identity correctly", async function () {

  //   });

  //   it("should fail to verify an identity if it does not match", async function () {

  //   });
});
