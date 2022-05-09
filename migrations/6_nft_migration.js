const IVIRSENFT = artifacts.require("IVIRSENFT");

module.exports = function (deployer) {
  deployer.deploy(IVIRSENFT, "0x3776ad6E321a3d2d2b78fF40D6b18d30E9F0E484");
};
