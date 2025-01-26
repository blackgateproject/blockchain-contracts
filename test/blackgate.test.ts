import { Deployer } from "@matterlabs/hardhat-zksync";
import { expect } from "chai";
import * as hre from "hardhat";
import { Contract, Provider, Wallet, types } from "zksync-ethers";

const RICH_WALLET_PK =
  "0x7726827caac94a7f9e1b160f7ea819f172f7b6f9d2a97f992c38edeab82d4110";

describe("Initial Deployment", function () {
  // Test deployment of all 3 contracts
  it("Should deploy RSAAccumulatorVerifier", async function () {
    const provider = Provider.getDefaultProvider(types.Network.EraTestNode);

    const wallet = new Wallet(RICH_WALLET_PK, provider);
    const deployer = new Deployer(hre, wallet);

    const modulus =
      "0x13c386cd86a84b8da9b21fced7bec3a82d8410b7328f171fa561cc6882b2c999960c980892fef3baac33a2b37751ce69b01d406a3c46e9bec81a16e8b1390c36c5668ab1c9d967f48013a2269674137cf7398ee7d858cc33d5fac9ff66d184d57e22b382dd67340d578ae3c0c1dff8a9772f793808b372b82e7579b0b806468cfc9c7f9816a56904d044ff35b44ec304743591b7015b8d350543834ffc5bf2b45f5eaf0431770f6c6146174843e2b527d0791ea3867d11091f7d347f5bfeab0e74e219b949077b457b7d52372e6ee58493fc90e7f8f8445c86aff9a688f207c3b5a3055babc69ddaf20ce30375343c2d051a065b77ff26efe34b2596558a45575bd991cb2ebf18d89cc1fd1a2344eea2c003ee2461457cb30874518d59abf5362c4173564b73fa529a65c35379dcb5aafe1f3caee23b8e16d90c7846c4409b5c41b36bbc039cfed3682f382e741bb8d558d194e1b9b2e810b7f6c7918f8fbd3baa2f56d26faf81c65e8fca00bfb103c51c95af7724cdc99ca053ae34b52de5a3";
    const accumulatorPost =
      "0x0e3a71c11edd0072df534f338cc464069e88ba2ce3768d820b42667fa0da974d7d72fb083f2beb4c9be27c23c2f48317fca3af84e01987624bee505946053a8e0d3fd318be1a19407d99e2186b6c0022561c29ca140e0202861259ee7babcf6bb711988bc21f0054defd086a4630f7b8df2555a11584598071fb6fd80debd725a950d7bd85db419c43d5579f8240a8bb7e485005443d2f9b08209813b7e2d8bd063148a97796e5a6b277527744828afcaf0d38d289b25a6ddfddba122157c8f0f114770e7a970b5d5df751cd61df63616074bd26f39d73f4c098ebfe02c7091d3429aaee54165bc0015953db10aebb23cf07e216ca482f77a1e0523e8e63cbe6f5bb5b232719d9d005afee9ab577c58b48f0c7519fc31dca3a5275b5abb14e82be629f9f924caea7fee3f67abadd47296a4ea07d227199fcbe5f053beac980ccc0411be7910c883b5d3dfa894934639e7c11657f3645626fe989dd4ec98db968533e5be99af03aba58a156d907e28895209958d4b13e6e3d9156783e24dd0889";

    const artifact = await deployer.loadArtifact("RSAAccumulatorVerifier");
    const DeployedRSAACC = await deployer.deploy(artifact, [
      modulus,
      accumulatorPost,
    ]);
    // console.log("Supposed Address for RSAAccumulatorVerifier",DeployedRSAACC.target);
    expect(DeployedRSAACC).to.be.instanceOf(Contract);
  });

  it("Should deploy DIDRegistry", async function () {
    const provider = Provider.getDefaultProvider(types.Network.EraTestNode);

    const wallet = new Wallet(RICH_WALLET_PK, provider);
    const deployer = new Deployer(hre, wallet);

    const artifact = await deployer.loadArtifact("DIDRegistry");
    const DeployedDIDReg = await deployer.deploy(artifact, []);

    expect(DeployedDIDReg).to.be.instanceOf(Contract);
  });

  it("Should deploy VerifiableCredentialManager(NoDIDReg)", async function () {
    const provider = Provider.getDefaultProvider(types.Network.EraTestNode);

    const wallet = new Wallet(RICH_WALLET_PK, provider);
    const deployer = new Deployer(hre, wallet);

    const artifact = await deployer.loadArtifact("VerifiableCredentialManager");
    const DeployedVCManager = await deployer.deploy(artifact, [
      "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
    ]);

    expect(DeployedVCManager).to.be.instanceOf(Contract);
  });

  it("Should deploy VerifiableCredentialManager(DIDReg)", async function () {
    const provider = Provider.getDefaultProvider(types.Network.EraTestNode);

    const wallet = new Wallet(RICH_WALLET_PK, provider);
    const deployer = new Deployer(hre, wallet);

    const artifact1 = await deployer.loadArtifact("DIDRegistry");
    const DeployedDIDReg = await deployer.deploy(artifact1, []);

    expect(DeployedDIDReg).to.be.instanceOf(Contract);

    const artifact = await deployer.loadArtifact("VerifiableCredentialManager");
    const DeployedVCManager = await deployer.deploy(artifact, [
      DeployedDIDReg.target,
    ]);

    expect(DeployedVCManager).to.be.instanceOf(Contract);
  });
});
