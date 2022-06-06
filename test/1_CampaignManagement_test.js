const TuanToken = artifacts.require("TuanToken");
const CampaignManagement = artifacts.require("CampaignManagement");

const {
  BN, // Big Number support
  constants, // Common constants, like the zero address and largest integers
  expectEvent, // Assertions for emitted events
  expectRevert,
  time, // Assertions for transactions that should fail
} = require("@openzeppelin/test-helpers");

const decimals = Math.pow(10, 18);
contract("TuanToken", (accounts) => {
  let token, campaignManagement;
  before("Init smart contract", async () => {
    token = await TuanToken.deployed();
    campaignManagement = await CampaignManagement.deployed();
  });
  describe("Check role", () => {
    it("total token unlock", async () => {
      let totalTokenUnlock = await campaignManagement.getTotalCanUse();
      console.log(totalTokenUnlock.toString());

      let datas = await campaignManagement.getDatas();
      await campaignManagement.createCampaign(
        "tuandq",
        [accounts[0]],
        [datas[0].amount]
      );
      let participants = await campaignManagement.getParticipants("tuandq");
      console.log(participants);
      let number = 10000000;
      let number2 = 10000000;

      await campaignManagement.updateCampaign(
        "tuandq",
        [accounts[1], accounts[2]],
        [number, number2]
      );
      participants = await campaignManagement.getParticipants("tuandq");
      console.log(participants);

      await campaignManagement.adminAcceptRelease("tuandq");
      await campaignManagement.release("tuandq", true);
      // await campaignManagement.release("tuandq", false);

      totalTokenUnlock = await campaignManagement.getTotalCanUse();

      console.log(totalTokenUnlock.toString());
    });
  });
});
