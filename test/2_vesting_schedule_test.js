const IVIRSE = artifacts.require("IVIRSE");
const VestingSchedule = artifacts.require("VestingSchedule");
const {
  BN, // Big Number support
  constants, // Common constants, like the zero address and largest integers
  expectEvent, // Assertions for emitted events
  expectRevert,
  time, // Assertions for transactions that should fail
} = require("@openzeppelin/test-helpers");

contract("VestingSchedule", (accounts) => {
  let ivi,
    vesting,
    owner = accounts[0],
    totalToken = 100000000 * Math.pow(10, 18);
  before("Deploy contracts", async () => {
    ivi = await IVIRSE.deployed();
    vesting = await VestingSchedule.deployed();
    let times = await vesting.getTimes();
    console.log("times", times);
  });
  describe("Multiple contract", () => {
    it("Check mint if owner", async () => {
      await ivi.mint(owner, totalToken);
      let balance = await ivi.balanceOf(owner);
      assert.equal(balance, totalToken);
    });

    it("Check allowance after approve", async () => {
      await ivi.approve(vesting.address, totalToken);
      let allowance = await ivi.allowance(owner, vesting.address);
      assert.equal(allowance, totalToken);
    });

    it("Add investor", async () => {
      let investorAddress = accounts[1];
      let investorAmount = "100000";
      let result = await vesting.addInvestor(investorAddress, investorAmount);
      expectEvent(result, "ADDINVESTOR", {
        _investorAddress: investorAddress,
        _amount: investorAmount,
      });
    });

    it("Test modifier", async () => {
      let investorAddress = accounts[2];
      let investorAmount = "100000";
      await expectRevert.unspecified(
        vesting.addInvestor(investorAddress, investorAmount, {
          from: investorAddress,
        }),
        "Unauthorized"
      );
    });
    it("Test time", async () => {
      await vesting.start();
      await time.increase(121);
      await vesting.sendCoinForInvestor();
    });
  });
});
