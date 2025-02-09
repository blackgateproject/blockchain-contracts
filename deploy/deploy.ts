import { deployContract } from "./utils";

// Deployment fails on verification in utils.ts deployContract()

export default async function () {
  // const modulus =
  //   "0x6bbd4e103665866439a28e98b1ab37e5b5ddc317a03e36636fdf8fe54a4aa7f5bfc90584901f2b3a88fa9149e15708d6ab1bb59fda79fe1d8ffa250f97646e8d787538dc3f0c4398b90a879bb823b0a313b1cffa2490bd1c7b41f898d34dd6071101cbcb5aa9a85674dc63e2c913b167e0e8950f8ce5d43d11cd6b69579d20d2ea5e0e5df7ea47f0141fd796341ea16f24ce34e13f0266b51791d672836049a124db7575b2a6a2c3545e54c9b8e7e60f4ef02346ea3fbc7787f81f70b70e25dd95261c31c0012f1f3a58a3875bd50338d925b8134be4ae1ab312211ffe59b666109bf47882ea855d43d69d47b5a29524aed42f1f46a5dc5e5a60c857963b0b7942ceff306d455edebd8a51396e7417cfa8db20e19fdd2b74d973108f4bc54e87bb8c6f252134ffbc8ae2010249cf9308f91214b09bb2accfeca26d07bcea1d43f4c5ea55092e6349b4ed590238efceccc8bf5d77c2cef1988a407f93e0c84addd9f1c229338bf23ccbce20c8517e0c8d863712e832874e6109141af38ab48a1d";

  // const contractArtifactName = "RSAAccumulatorVerifier";
  // const RSAAccumulatorVerifierCNTRT = await deployContract(
  //   contractArtifactName,
  //   [
  //     modulus,
  //     // accumulatorPost,
  //   ]
  // );

  const contractArtifactName2 = "EthereumDIDRegistry";
  const DIDREGCNTRT = await deployContract(contractArtifactName2, [], {
    // noVerify: true
  });

  const contractArtifactName3 = "VerifiableCredentialManager";
  // const VCMNGRCTRT = await deployContract(contractArtifactName3, [
  //   DIDREGCNTRT.target,
  // ], {
  //   // noVerify: true,
  // });
  const VCMNGRCTRT = await deployContract(contractArtifactName3, [], {
    // noVerify: true,
  });
  // console.log(
  //   "RSAAccumulatorVerifier deployed to:",
  //   RSAAccumulatorVerifierCNTRT.target
  // );
  console.log("EthereumDIDRegistry deployed to:", DIDREGCNTRT.target);
  console.log("VerifiableCredentialManager deployed to:", VCMNGRCTRT.target);
}
