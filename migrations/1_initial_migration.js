const Migrations = artifacts.require("./Migrations.sol");
const ComposableDown = artifacts.require("./ComposableTopDown.sol");
const SampleNFT = artifacts.require("./SampleNFT.sol");
const SampleERC20 = artifacts.require("./SampleERC20.sol");
const ComposableUp = artifacts.require("./ComposableBottomUp.sol");

module.exports = function(deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(ComposableDown, "ComposableTopDown", "COMPTD");
  deployer.deploy(SampleNFT, "SampleNFT", "SNFT");
  deployer.deploy(SampleERC20);
  deployer.deploy(ComposableUp);
};
