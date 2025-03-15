import { deployContract } from "./utils";

// Deployment fails on verification in utils.ts deployContract()

export default async function () {
  const contractArtifactName = "Merkle";
  const contract = await deployContract(contractArtifactName, [], {
    noVerify: false,
    silent: false,
  });
  console.log("Merkle deployed to:", contract);
  
  const contractArtifactName1 = "EthereumDIDRegistry";
  const contract1 = await deployContract(contractArtifactName1, [], {
    noVerify: false,
    silent: false,
  });
  console.log("ETHR-DID-REG deployed to:", contract1);


}
