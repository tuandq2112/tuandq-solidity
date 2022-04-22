const IVIRSE = artifacts.require("IVIRSE");
const TokenTimelock = artifacts.require("TokenTimelock");
const {
  BN, // Big Number support
  constants, // Common constants, like the zero address and largest integers
  expectEvent, // Assertions for emitted events
  expectRevert,
  time, // Assertions for transactions that should fail
} = require("@openzeppelin/test-helpers");
const { assertion } = require("@openzeppelin/test-helpers/src/expectRevert");

contract("TokenTimelock", (accounts) => {
  describe("Multiple contract", () => {
    let ivi,
      timeLock,
      owner = accounts[0],
      amounts = [];

    before("Deploy contracts", async () => {
      ivi = await IVIRSE.deployed();
      timeLock = await TokenTimelock.deployed();
      for (let i = 0; i < accounts.length; i++) {
        amounts.push(Math.floor(Math.random() * 100));
      }
      await timeLock.setBeneficiaryAmounts(ivi.address, accounts, amounts);
      await timeLock.setTimesAndRate(
        4,
        [20, 20, 30, 30],
        [10000, 20000, 30000, 40000]
      );
      await ivi.mint(
        timeLock.address,
        amounts.reduce((a, b) => a + b, 0)
      );
    });
    it("Check release", async () => {
      await timeLock.startRelease();
      await time.increase(10000);
      await timeLock.release();
    });
    // it("Check release2", async () => {
    //   
    // });
    it("Check allowance", async () => {
      for (let i = 0; i < accounts.length; i++) {
        let allowance = await ivi.allowance(timeLock.address, accounts[i]);
        console.log(allowance, Math.floor(amounts[i] * 0.2), amounts[i]);
        assert.equal(allowance, Math.floor(amounts[i] * 0.2));
      }
    });
  });
});
