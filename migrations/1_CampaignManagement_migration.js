const TuanToken = artifacts.require("TuanToken");
const CampaignManagement = artifacts.require("CampaignManagement");
let strDate = "2022/05";
module.exports = function (deployer, network, accounts) {
  deployer.deploy(TuanToken).then((res) => {
    let now = new Date(strDate);

    return deployer.deploy(
      CampaignManagement,
      res.address,
      accounts
        .slice(1, 10)
        .map((item, index) =>
          Math.round(new Date(strDate).setMonth(now.getMonth() + index) / 1000)
        ),
      accounts.slice(1, 10).map((str) => parseInt(str.substring(0, 3)))
    );
  });
};
