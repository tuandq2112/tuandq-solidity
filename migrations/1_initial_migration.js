const Migrations = artifacts.require("Migrations");

module.exports = function (deployer) {
  deployer.deploy(Migrations);
};

const IvirseToken = artifacts.require("IvirseToken");

module.exports = function (deployer) {
  deployer.deploy(IvirseToken);
};

const IHealthToken = artifacts.require("IHealthToken");

module.exports = function (deployer) {
  deployer.deploy(IHealthToken);
};