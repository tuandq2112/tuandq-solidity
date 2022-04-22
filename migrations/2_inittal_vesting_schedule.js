const VestingSchedule = artifacts.require("VestingSchedule");

const IVIRSE = artifacts.require("IVIRSE");

module.exports = function (deployer) {
  deployer.deploy(IVIRSE).then(() => {
    return deployer.deploy(VestingSchedule, 2, 2, IVIRSE.address);
  });
};
