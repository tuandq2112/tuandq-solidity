const BatchManagement = artifacts.require("BatchManagement");

module.exports = function (deployer) {
  deployer.deploy(
    BatchManagement,
    "0xD205C35e8667E2b63eb43388f154bfc22f48Abe1"
  );
};
