const IvirseToken = artifacts.require("IvirseToken");

module.exports = function (deployer) {
  deployer.deploy(IvirseToken);
};