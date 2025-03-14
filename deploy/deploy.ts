import { deployContract } from "./utils";

// Deployment fails on verification in utils.ts deployContract()

export default async function () {
  const contractArtifactName = "Merkle";
  const contract = await deployContract(contractArtifactName, [], {
    noVerify: false,
    silent: false,

  });
  console.log("Merkle deployed to:", contract);
}
