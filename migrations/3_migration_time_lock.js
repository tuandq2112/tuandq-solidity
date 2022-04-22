const TokenTimelock = artifacts.require("TokenTimelock");

const IVIRSE = artifacts.require("IVIRSE");

module.exports = function (deployer) {
  deployer.deploy(IVIRSE).then(() => {
    return deployer.deploy(TokenTimelock);
  });
};
