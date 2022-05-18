const TimeLock = artifacts.require("TimeLock");

const IVIRSE = artifacts.require("IVIRSE");

module.exports = function (deployer) {
  deployer.deploy(IVIRSE).then(() => {
    return deployer.deploy(TimeLock);
  });
};
