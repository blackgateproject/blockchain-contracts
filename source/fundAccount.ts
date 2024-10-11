import { ethers } from "ethers";

// Connect to the local Hardhat blockchain
const provider = new ethers.JsonRpcProvider("http://127.0.0.1:8545");

export default async function fundAccount(accountAddress: string, amount: string) {
  try {
    // Get the wallet (first account) from the provider
    const signer = provider.getSigner(0); // Get the first account from the Hardhat node

    // Parse the amount to Wei
    const value = ethers.parseEther(amount);

    // Send the transaction
    const txResponse = await (await signer).sendTransaction({
      to: accountAddress,
      value: value,
    });

    // Wait for the transaction to be mined
    const receipt = await txResponse.wait();

    // console.log(`Transaction successful with hash: ${receipt.transactionHash}`);
    console.log(`Transaction successful with hash: ${receipt?.hash}`);
  } catch (error) {
    console.error("Error funding account:", error);
  }
}

// Replace with your desired account address and amount to fund
// fundAccount("0x175f4EA914dc3DeF6a41E76a94CD8Ad3b437a94f", "1.0");
