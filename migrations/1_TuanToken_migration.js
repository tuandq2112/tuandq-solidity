const TuanToken = artifacts.require("TuanToken");

module.exports = function (deployer) {
  deployer.deploy(TuanToken);
};
