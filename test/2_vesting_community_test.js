const TuanToken = artifacts.require("TuanToken");
const VestingCommunity = artifacts.require("VestingCommunity");

const {
  BN, // Big Number support
  constants, // Common constants, like the zero address and largest integers
  expectEvent, // Assertions for emitted events
  expectRevert,
  time, // Assertions for transactions that should fail
} = require("@openzeppelin/test-helpers");

const decimals = Math.pow(10, 18);
contract("TuanToken", (accounts) => {
  let token, community, newDate;
  before("Init smart contract", async () => {
    token = await TuanToken.deployed();
    community = await VestingCommunity.deployed();
  });
  describe("Community", () => {
    it("Test community 1", async () => {
      let newTime = await time.latest();
      newDate = newTime.toNumber() + 100;
      await expectRevert.unspecified(
        community.addAccounts([accounts[1]], [BigInt(100 * decimals)], newDate),
        "Exceed balance"
      );
    });
    it("Test community 2", async () => {
      await token.mint(community.address, BigInt(800 * decimals));
      await community.addAccounts(
        accounts.slice(1, 9),

        Array.from(new Array(8), () => {
          return BigInt(100 * decimals);
        }),

        newDate
      );
    });
    it("Test community 3", async () => {
      let times = await community.getTimes();
      let newTime = times.map((item) => item.toNumber());
      await time.increaseTo(newDate);
      await community.claimToken(newTime[0], 0, { from: accounts[1] });
      await expectRevert.unspecified(
        community.claimToken(newTime[0], 0, { from: accounts[1] }),
        "Invalid"
      );
      await community.claimToken(newTime[0], 2, { from: accounts[3] });
    });
    it("Admin consensus", async () => {
      let times = await community.getTimes();

      let newTime = times.map((item) => item.toNumber());

      await community.adminAccept();
      await community.addAdmin(accounts[1]);
      await community.adminAccept();
      await community.adminAccept({ from: accounts[1] });
      await community.addAdmin(accounts[2]);
      await community.adminAccept();
      await community.adminAccept({ from: accounts[1] });
      await community.adminAccept({ from: accounts[2] });
      await community.pause({ from: accounts[1] });
      await community.adminAccept();
      await community.adminAccept({ from: accounts[1] });
      await community.adminAccept({ from: accounts[2] });
      await community.unpause({ from: accounts[1] });

      await community.claimToken(newTime[0], 1, { from: accounts[2] });
      await community.adminAccept();
      await community.adminAccept({ from: accounts[1] });
      await community.revokeAdminRole(accounts[1], { from: accounts[0] });
      await community.adminAccept();
      await community.adminAccept({ from: accounts[2] });
      await community.pause({ from: accounts[0] });
      // await community.unpause({ from: accounts[1] });
    });
  });
});
