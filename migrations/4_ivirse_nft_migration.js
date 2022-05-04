const IVIRSENFT = artifacts.require("IVIRSENFT");
const IVIRSE = artifacts.require("IVIRSE");

module.exports = async function (deployer) {
  deployer.deploy(IVIRSE).then(() => {
    return deployer.deploy(IVIRSENFT, IVIRSE.address);
  });
};
