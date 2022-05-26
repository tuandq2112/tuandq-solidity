const TuanToken = artifacts.require("TuanToken");
const VestingCommunity = artifacts.require("VestingCommunity");

module.exports = function (deployer) {
  deployer.deploy(TuanToken).then((res) => {
    return deployer.deploy(VestingCommunity, res.address);
  });
};
