const TimeLock2 = artifacts.require("TimeLock2");

const IVIRSE = artifacts.require("IVIRSE");

module.exports = function (deployer) {
  deployer.deploy(IVIRSE).then(() => {
    return deployer.deploy(TimeLock2, IVIRSE.address);
  });
};
