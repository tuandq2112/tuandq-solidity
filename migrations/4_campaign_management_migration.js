const CampaignManagement = artifacts.require("CampaignManagement");
let strDate = "2021/05";
module.exports = function (deployer, network, accounts) {
  let currentDate = new Date(strDate);
  let times = Array.from(new Array(31), (el, index) => {
    return Math.round(
      new Date(strDate).setMonth(currentDate.getMonth() + index) / 1000
    );
  });
  console.log(
    times,
    times.map((item) => Math.round(Math.random() * 300))
  );

  deployer.deploy(
    CampaignManagement,
    "0x4f730f7a5acebA1CdBf6EB5aAeB8686D8eA37680",
    times,
    times.map((item) => Math.round(Math.random() * 300))
  );
};
